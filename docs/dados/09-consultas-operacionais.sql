-- DP-009 | Consultas de referencia (PostgreSQL)
-- Estas consultas nao executam alteracoes de dados e usam parametros tipados.
-- Ao implementar, a camada de acesso deve parametrizar entradas e paginar resultados.
-- Exemplos PREPARE podem ser executados apos aplicar o DDL no ambiente local.

-- 1. Listar dispositivos por situacao (texto de comunicacao e codigos).
PREPARE dp_devices_by_status (text, integer, integer) AS
SELECT id, code, name, connectivity_status, last_battery_level, last_event_at
FROM devices
WHERE ($1 IS NULL OR connectivity_status = $1)
ORDER BY code ASC, id ASC
LIMIT $2 OFFSET $3;

-- 2. Historico por dispositivo; ordenacao deterministica inclusive em empates.
PREPARE dp_device_history (uuid, integer, integer) AS
SELECT id AS event_id, device_id, occurred_at, received_at, battery_level
FROM device_events
WHERE device_id = $1
ORDER BY occurred_at DESC, id DESC
LIMIT $2 OFFSET $3;

-- 3. Alertas ainda abertos por tipo (NULL = qualquer tipo).
PREPARE dp_open_alerts (text, integer, integer) AS
SELECT a.id, a.device_id, d.code, a.alert_type,
       a.opened_at, a.acknowledged_at, a.resolved_at
FROM alerts AS a
JOIN devices AS d ON d.id = a.device_id
WHERE a.resolved_at IS NULL
  AND ($1 IS NULL OR a.alert_type = $1)
ORDER BY a.opened_at DESC, a.id DESC
LIMIT $2 OFFSET $3;

-- 4. Historico completo de alertas por dispositivo.
PREPARE dp_device_alert_history (uuid, integer, integer) AS
SELECT id, alert_type, opened_at, acknowledged_at, resolved_at, source_event_id
FROM alerts
WHERE device_id = $1
ORDER BY opened_at DESC, id DESC
LIMIT $2 OFFSET $3;

-- 5. Indicadores do dashboard; evita multiplicar linhas em JOINs de contagem.
SELECT
 (SELECT COUNT(*) FROM devices) AS devices_total,
 (SELECT COUNT(*) FROM devices WHERE connectivity_status = 'ONLINE') AS devices_online,
 (SELECT COUNT(*) FROM devices WHERE connectivity_status = 'OFFLINE') AS devices_offline,
 (SELECT COUNT(*) FROM devices WHERE connectivity_status = 'SEM_DADOS') AS devices_sem_dados,
 (SELECT COUNT(*) FROM alerts WHERE resolved_at IS NULL) AS open_alerts_total,
 (SELECT COUNT(*) FROM alerts
   WHERE resolved_at IS NULL AND acknowledged_at IS NULL) AS open_unacknowledged_alerts;

-- 6. Candidatos que ja passaram de CINCO minutos desde a ultima comunicacao.
-- A comparacao < preserva a regra estrita "mais de 300 segundos" (na igualdade ainda online).
SELECT id, code, last_event_at, connectivity_status
FROM devices
WHERE last_event_at IS NOT NULL
  AND last_event_at < clock_timestamp() - INTERVAL '300 seconds'
ORDER BY last_event_at ASC;

-- 7. Reconhecimento atomico com guardas de negocio.
-- Substituir $1 pelo UUID do alerta na aplicacao, antes de executar.
-- Se nenhuma linha for atualizada: consultar o alerta para distinguir
-- "inexistente", "ja reconhecido" e "ja resolvido".
PREPARE dp_acknowledge_open_alert (uuid) AS
UPDATE alerts
SET acknowledged_at = clock_timestamp()
WHERE id = $1
  AND resolved_at IS NULL
  AND acknowledged_at IS NULL
RETURNING id, device_id, alert_type, acknowledged_at, resolved_at;

-- Observacao importante: uma consulta nao substitui a transacao de ingestao.
-- Para uma medicao nova, o backend deve bloquear devices FOR UPDATE,
-- inserir em device_events verificando o eventId e so atualizar devices/alerts
-- se occurred_at for ESTRITAMENTE MAIOR que last_event_at.
-- O indice unico parcial protege (device_id, alert_type) enquanto resolved_at IS NULL.

-- Ao testar no psql com IDs artificiais:
-- EXECUTE dp_devices_by_status(NULL, 20, 0);
-- EXECUTE dp_open_alerts(NULL, 20, 0);
