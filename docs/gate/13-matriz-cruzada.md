# DP-013 — Matriz de consistência: regra × dados × API × interface × QA

**Versão:** 0.1 — revisão do pacote, não aceite funcional
**Fonte contratual:** [OpenAPI 1.0](../api/10-openapi.json); [DER](../09-modelo-dados-e-dicionario.md); [Regras](../04-regras-de-negocio-e-estados.md); [UX](../11-wireframes-fluxos-interfaces.md); [casos de teste](../qa/12-casos-teste.csv).

## 1. As nove operações REST autorizadas

| Operação | Componente / dados relevantes | Interface ou cliente | Testes associados (amostra) |
| --- | --- | --- | --- |
| `POST /devices` | devices, código UNIQUE, SEM_DADOS | UX-03 | QA-001, QA-002, QA-003, QA-004, QA-049 (7 planejados) |
| `GET /devices` | devices + índice connectivity_status/code | UX-02 | QA-005, QA-006, QA-007, QA-008, QA-009 (11 planejados) |
| `GET /devices/{deviceId}` | devices por UUID | UX-04 | QA-008, QA-009, QA-023 (3 planejados) |
| `GET /devices/{deviceId}/events` | device_events + índice (device_id, occurred_at, id) | UX-04 | QA-023 (1 planejados) |
| `POST /events` | device_events (eventId), devices, alerts; transação | Simulador CLI | QA-010, QA-014, QA-015, QA-016, QA-017 (22 planejados) |
| `GET /alerts` | alerts + índice aberto parcial; devices | UX-01 / UX-05 | QA-042, QA-043, QA-059, QA-068, QA-074 (5 planejados) |
| `GET /alerts/{alertId}` | alerts por UUID | UX-06 | QA-043 (1 planejados) |
| `POST /alerts/{alertId}/acknowledge` | alerts.acknowledged_at, resolved_at guardado | UX-06 | QA-037, QA-038, QA-039, QA-040, QA-046 (6 planejados) |
| `GET /dashboard/summary` | devices + alerts (contagens) | UX-01 | QA-044, QA-045, QA-051, QA-063 (4 planejados) |

**Critério:** nenhuma tela deve gerar nova operação CRUD sem contrato. `GET /devices?q=...` cumpre a busca por nome/código; não existem `PUT`, `PATCH`, `DELETE` de dispositivo ou `POST resolve` manual. O simulador usa `POST /events`, não a conexão PostgreSQL diretamente.

## 2. Invariantes transversais

| ID | Regra verificável | Elemento da persistência | Impacto UX/API | Família de QA |
| --- | --- | --- | --- | --- |
| INV-01 | Novo cadastro sem medição começa em SEM_DADOS | devices.last_event_at e last_battery_level nulos | GET retorna SEM_DADOS e bateria null; UI “Aguardando dados” | QA-001, QA-009 |
| INV-02 | Bateria baixa <=20; normal >20 | last_battery_level CHECK 0..100 | JSON batteryStatus BAIXA/NORMAL; texto UI explícito | QA-011, QA-012, QA-013 |
| INV-03 | Offline estritamente >300s e verificação a cada 30s | devices.last_event_at | SEM_DADOS nunca offline; UI mostra Sem comunicação | QA-025..QA-030 |
| INV-04 | Replay idêntico de eventId é 200 idempotente | device_events.id PK | processingResult ALREADY_PROCESSED; sem atualizar alertas | QA-019 |
| INV-05 | EventId repetido divergente é 409 | device_events.id PK + comparação do serviço | EVENT_ID_CONFLICT; sem overwrite | QA-020 |
| INV-06 | Evento novo atrasado vai só ao histórico | device_events.occurred_at + devices.last_event_at | 201 HISTORY_ONLY; estado atual imutável | QA-021, QA-022 |
| INV-07 | Uma ocorrência aberta por tipo/device, mesmo concorrendo | índice parcial ux_alerts_open_device_type | lista sem alertas abertos duplicados | QA-031, QA-032 |
| INV-08 | Alerta de bateria e de offline podem coexistir | alerts.alert_type + uniques por tipo | telas não misturam duas condições | QA-033, QA-034 |
| INV-09 | Reconhecer não resolve; resolução não exige reconhecer | alerts.acknowledged_at/resolved_at | POST acknowledge 200 e UI aberta/reconhecida | QA-035..QA-041 |
| INV-10 | Reconhecimento após resolução bloqueado | UPDATE condicional e check de datas | HTTP 409, ocultar botão após atualizar | QA-039..QA-041 |
| INV-11 | Falha de DB não retorna sucesso confirmado | transações/rollback e reconciliação | HTTP 503 conhecido, 500 inesperado; UX erro/retry | QA-059..QA-063, QA-077..QA-079 |
| INV-12 | Dashboard e listas paginadas respondem <=2s no cenário local | índices, paginação, SQL | 100 devices/10 mil events, 1 request por vez | QA-064 |
| INV-13 | Sem segredos nem dados reais e sem escrita pública irrestrita | configuração / controle de rede | demo local primeiro, SEC-01..SEC-20 | QA segurança e SEC |
 
## 3. Precedência para divergências históricas

O DP-003 descreve capacidades; o DP-004 define a semântica temporal; DP-005/006/007 representam o comportamento do processo; DP-009 define integridade; **DP-010 estabelece o contrato HTTP definitivo**; DP-011 define a interface e DP-012 as evidências de qualidade.

Exemplos de códigos 500 de documentos BPMN anteriores são registros históricos de uma resposta genérica. O backend **não** deve implementá-los literalmente para toda falha do banco: usar **503** para indisponibilidade conhecida e **500** para erro inesperado. **O XML e as prévias BPMN precisam ser alinhados e revisados visualmente no modelador antes da aprovação do gate.**

A semântica `status` e `acknowledged` em JSON vem de `resolved_at` e `acknowledged_at` e **não** deve originar colunas textuais redundantes no banco.

## 4. Limitações desta revisão

Esta matriz verifica **consistência documental**. Não executou PostgreSQL, API, React, simulador nem testes automatizados. Os números dos testes são referências do CSV, cujo status é NÃO_EXECUTADO; as fontes Mermaid e SVG não são evidência de UI implementada.

**Operações sem teste mapeado pela coluna de operação, se houver:** nenhuma na checagem documental baseada em correspondência de operação e passos.
