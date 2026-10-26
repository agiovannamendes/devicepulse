-- DevicePulse | DP-009 | Modelo fisico PostgreSQL | PROPOSTA v0.1
-- Somente dados ficticios. Este arquivo e referencia de DDL, nao uma migracao aplicada.
-- UUIDs de dispositivos, eventos e alertas serao gerados no backend/simulador.
-- Versao exata de PostgreSQL, ferramenta de migracao e ambiente: confirmar antes do desenvolvimento.
-- Referencias: DP-004 RN-001..RN-023, DP-008 ADR-002 e DP-007.
BEGIN;

CREATE TABLE devices (
    id UUID PRIMARY KEY,
    code VARCHAR(50) NOT NULL,
    name VARCHAR(120) NOT NULL,
    connectivity_status VARCHAR(12) NOT NULL DEFAULT 'SEM_DADOS',
    last_battery_level SMALLINT NULL,
    last_event_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_devices_code UNIQUE (code),
    CONSTRAINT ck_devices_code_normalized CHECK (code ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT ck_devices_name_not_blank CHECK (length(btrim(name)) > 0),
    CONSTRAINT ck_devices_connectivity CHECK (
        connectivity_status IN ('SEM_DADOS', 'ONLINE', 'OFFLINE')
    ),
    CONSTRAINT ck_devices_last_battery CHECK (
        last_battery_level IS NULL OR last_battery_level BETWEEN 0 AND 100
    ),
    CONSTRAINT ck_devices_state_consistency CHECK (
        (connectivity_status = 'SEM_DADOS'
            AND last_event_at IS NULL
            AND last_battery_level IS NULL)
        OR
        (connectivity_status IN ('ONLINE', 'OFFLINE')
            AND last_event_at IS NOT NULL
            AND last_battery_level IS NOT NULL)
    ),
    CONSTRAINT ck_devices_updated_at CHECK (updated_at >= created_at)
);

CREATE TABLE device_events (
    id UUID PRIMARY KEY,          -- corresponde a eventId enviado pelo simulador
    device_id UUID NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL,
    received_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    battery_level SMALLINT NOT NULL,

    CONSTRAINT fk_device_events_device
        FOREIGN KEY (device_id) REFERENCES devices (id)
        ON DELETE RESTRICT,
    CONSTRAINT ck_device_events_battery
        CHECK (battery_level BETWEEN 0 AND 100),
    -- Necessario para que um alerta referencie um evento do MESMO dispositivo.
    -- A PK id continua global, de modo que eventId repetido em outro dispositivo conflita.
    CONSTRAINT uq_device_events_id_device UNIQUE (id, device_id)
);

CREATE TABLE alerts (
    id UUID PRIMARY KEY,
    device_id UUID NOT NULL,
    alert_type VARCHAR(20) NOT NULL,
    source_event_id UUID NULL,
    opened_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    acknowledged_at TIMESTAMPTZ NULL,
    resolved_at TIMESTAMPTZ NULL,

    CONSTRAINT fk_alerts_device
        FOREIGN KEY (device_id) REFERENCES devices (id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_alerts_source_event_same_device
        FOREIGN KEY (source_event_id, device_id)
        REFERENCES device_events (id, device_id)
        ON DELETE RESTRICT,
    CONSTRAINT ck_alerts_type CHECK (
        alert_type IN ('LOW_BATTERY', 'NO_COMMUNICATION')
    ),
    -- Bateria baixa decorre de um evento; offline decorre da ausencia de evento novo.
    CONSTRAINT ck_alerts_source_kind CHECK (
        (alert_type = 'LOW_BATTERY' AND source_event_id IS NOT NULL)
        OR
        (alert_type = 'NO_COMMUNICATION' AND source_event_id IS NULL)
    ),
    CONSTRAINT ck_alerts_ack_order CHECK (
        acknowledged_at IS NULL OR acknowledged_at >= opened_at
    ),
    CONSTRAINT ck_alerts_resolution_order CHECK (
        resolved_at IS NULL OR resolved_at >= opened_at
    ),
    CONSTRAINT ck_alerts_ack_before_resolution CHECK (
        acknowledged_at IS NULL
        OR resolved_at IS NULL
        OR acknowledged_at <= resolved_at
    )
);

-- Indices de consultas: dispositivos filtrados por conectividade ou expiracao.
CREATE INDEX idx_devices_connectivity_code
    ON devices (connectivity_status, code);

CREATE INDEX idx_devices_last_event_at
    ON devices (last_event_at)
    WHERE last_event_at IS NOT NULL;

-- Historico cronologico paginavel por dispositivo e auditoria de recebimento.
CREATE INDEX idx_device_events_device_occurred
    ON device_events (device_id, occurred_at DESC, id DESC);

CREATE INDEX idx_device_events_received
    ON device_events (received_at DESC, id DESC);

-- Uma medicao ficticia pode originar, no maximo, uma abertura LOW_BATTERY.
CREATE UNIQUE INDEX ux_alerts_source_event
    ON alerts (source_event_id)
    WHERE source_event_id IS NOT NULL;

-- Historico de alertas por dispositivo, incluindo os resolvidos.
CREATE INDEX idx_alerts_device_opened
    ON alerts (device_id, opened_at DESC, id DESC);

-- Garantia de banco: no maximo UM alerta NAO RESOLVIDO por dispositivo e tipo.
-- Alertas resolvidos podem se repetir historicamente.
CREATE UNIQUE INDEX ux_alerts_open_device_type
    ON alerts (device_id, alert_type)
    WHERE resolved_at IS NULL;

-- Filtro operacional de alertas abertos por tipo, do mais recente para o mais antigo.
CREATE INDEX idx_alerts_open_type_opened
    ON alerts (alert_type, opened_at DESC, id DESC)
    WHERE resolved_at IS NULL;

-- Historico de alertas encerrados, quando filtrados por data de resolucao.
CREATE INDEX idx_alerts_resolved_at
    ON alerts (resolved_at DESC, id DESC)
    WHERE resolved_at IS NOT NULL;

COMMIT;

-- Integridade dependente de servico/transacao (nao totalmente exprimivel por CHECK):
-- 1. occurred_at com instante futuro: rejeitar no backend antes de gravar;
-- 2. comparar o payload inteiro ao reenviar eventId; mesmo id e conteudo => idempotente;
-- 3. gravar evento + atualizar estado e alertas em UMA transacao coerente;
-- 4. bloquear a linha do dispositivo em transacoes concorrentes (SELECT ... FOR UPDATE),
--    comparar occurred_at > last_event_at; empate/mais antigo so adiciona historico;
-- 5. a checagem a cada 30 segundos calcula offline com tempo atual > last_event_at + 300 s;
-- 6. reconhecer so enquanto resolved_at IS NULL, com UPDATE condicional;
-- 7. nao excluir fisicamente historicos no MVP; uma exclusao de device e restringida por FKs;
-- 8. atualizar updated_at pelo backend, inclusive em alteracoes transacionais;
-- 9. estado de bateria e derivado de last_battery_level: SEM_DADOS, BAIXA (<=20) ou NORMAL (>20).
