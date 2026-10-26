# DP-010 — Contratos REST e OpenAPI

**Versão:** 0.1  
**Situação:** Em revisão — não aprovado  
**Card:** DP-010  
**Projeto:** DevicePulse — eventos e dispositivos exclusivamente fictícios  
**Dependências:** [DP-003 — Requisitos](03-requisitos-funcionais-e-nao-funcionais.md), [DP-004 — Regras](04-regras-de-negocio-e-estados.md), [DP-009 — DER e Dicionário](09-modelo-dados-e-dicionario.md)  
**Arquitetura:** [DP-008 — C4 e ADRs](08-arquitetura-c4-fluxo-dados.md)

## 1. Objetivo e artefatos

Estabelecer um contrato versionado para as interações entre a SPA React, o simulador Node.js e a API Node.js/Express. A API é **proposta para desenvolvimento**, ainda não implementada.

- **Fonte normativa:** [OpenAPI 3.1 em JSON](api/10-openapi.json) — esquemas, rotas, exemplos, parâmetros, respostas e erros.
- **Exemplos editáveis:** [Requisições .http](api/10-exemplos-requisicoes.http) — podem ser abertas num cliente HTTP compatível, após iniciar o backend.
- **Este documento:** visão funcional, rastreabilidade das ações, semântica, decisões e matriz de testes.

O formato `.json` é uma representação **válida de OpenAPI 3.1**, editável em qualquer editor; pode ser carregado em Swagger Editor ou ferramenta equivalente. Não é necessário gerar um arquivo YAML paralelo.

**Endereço local proposto:** `http://localhost:3000/api/v1`. A porta é configurável na implementação. Essa URL é um exemplo do contrato, **não indica que há servidor em execução**.

## 2. Convenções do contrato

| Convenção | Decisão proposta |
| --- | --- |
| Caminhos | `/api/v1` no endereço-base, com caminhos `/devices`, `/events`, `/alerts` e `/dashboard`. |
| Transportes | HTTP local; HTTPS obrigatório antes de publicação. JSON em corpos de requisição e resposta. |
| Identificador do dispositivo | `deviceId`: UUID técnico de `devices.id`; `code`: código legível normalizado para maiúsculas. |
| Identificador do evento | `eventId`: UUID global que é a PK de `device_events.id`. |
| Identificador de alerta | `alertId`: UUID de `alerts.id`. |
| Datas | Formato RFC 3339/ISO 8601 com fuso explícito na entrada, e respostas normalizadas em UTC. |
| Paginação | `page` inicia em 1, padrão 1; `pageSize` de 1 a 100, padrão 20. |
| Ordenação | Dispositivos por `code ASC, id ASC`; eventos por `occurredAt DESC, eventId DESC`; alertas por `openedAt DESC, id DESC`. |
| Listas vazias | HTTP 200 com `data: []` e `meta.totalItems: 0`, `meta.totalPages: 0`. |
| Erro | Corpo uniforme `{ "error": { "code", "message", "details" } }`; `requestId` opcional para rastreamento. |
| Autenticação | Não incluída no MVP local. Não expor os endpoints de escrita em uma demo pública sem proteção adequada. |
| Variáveis de configuração | Limiares de bateria e comunicação são do backend; **não** existe endpoint para alterá-los no MVP. |

As leituras usam `{ "data": ... }`; listagens adicionam `meta`; a ingestão acrescenta `processingResult`. Estados computados são apresentados em JSON sem criar novas colunas SQL.

## 3. Operações e rastreabilidade com a interface

| Ação do operador ou simulador | Método e caminho relativo a /api/v1 | Origem da regra |
| --- | --- | --- |
| Cadastrar dispositivo | `POST /devices` | RF-001; RN-001 |
| Listar dispositivos | `GET /devices` | RF-002 |
| Pesquisar código/nome | `GET /devices?q=SENSOR` | RF-003 |
| Filtrar situação da comunicação | `GET /devices?connectivityStatus=OFFLINE` | RF-003 |
| Paginar dispositivos | `GET /devices?page=2&pageSize=20` | RF-002/003 |
| Abrir detalhes de dispositivo | `GET /devices/{deviceId}` | RF-004 |
| Visualizar histórico de medições | `GET /devices/{deviceId}/events` | RF-008 |
| Simulador enviar medição | `POST /events` | RF-005/006/007; RN-002 a RN-006 |
| Consultar central de alertas | `GET /alerts` | RF-017 |
| Filtrar alertas por tipo, estado ou reconhecimento | `GET /alerts?status=OPEN&acknowledged=false` | RF-017; RN-019 a RN-023 |
| Abrir detalhe de alerta | `GET /alerts/{alertId}` | RF-017 |
| Reconhecer ocorrência aberta | `POST /alerts/{alertId}/acknowledge` (corpo vazio) | RF-015; RN-019 |
| Carregar indicadores do dashboard | `GET /dashboard/summary` | RF-018 |
| Atualizar dados da interface / recarregar painel | Repetir as operações GET correspondentes | RF-019 |
| Detectar offline e resolver alertas automaticamente | **Ação interna** do backend/verificador, sem endpoint de escrita para o operador | RF-011/014/016; RN-009/020 |

**Fora de escopo:** editar/excluir dispositivos, cadastrar usuário, login, resolver alertas manualmente, controlar o simulador pela UI, alterar limiares ou publicar eventos reais. Não criar endpoints extras para ações não aprovadas.

## 4. Requisições e respostas exemplificadas

Todos os UUIDs e horários a seguir são **inventados para demonstração**.

### 4.1 Cadastro de dispositivo

```http
POST /api/v1/devices
Content-Type: application/json

{"code":"SENSOR_001","name":"Sensor de demonstração 01"}
```

**201 Created** — resposta resumida:

```json
{"data":{
  "id":"383f7ac3-55f4-4891-8fa6-88253ce7b42c",
  "code":"SENSOR_001",
  "name":"Sensor de demonstração 01",
  "connectivityStatus":"SEM_DADOS",
  "batteryLevel":null,
  "batteryStatus":"SEM_DADOS",
  "lastEventAt":null,
  "batteryReadingIsStale":false,
  "createdAt":"2026-10-26T17:00:00Z",
  "updatedAt":"2026-10-26T17:00:00Z"
}}
```

A situação inicial **SEM_DADOS** não abre alerta. Código duplicado retorna **409**; dados inválidos, **400**. Os horários são ilustrativos.

### 4.2 Envio de evento fictício

```http
POST /api/v1/events
Content-Type: application/json

{
  "eventId":"7a4c4e36-88c9-4059-aa65-9b1e0b88b4be",
  "deviceId":"383f7ac3-55f4-4891-8fa6-88253ce7b42c",
  "occurredAt":"2026-10-26T14:00:00-03:00",
  "batteryLevel":15
}
```

Para **evento novo**, retorna **201**, o evento gravado com seu horário de recebimento e:
- `processingResult: "APPLIED"` quando a medição é mais recente e foi considerada para o estado;
- `processingResult: "HISTORY_ONLY"` quando é válida, mas seu horário é igual/anterior ao último aplicado.

Para **reenvio idêntico** de `eventId`, retorna **200** com `processingResult: "ALREADY_PROCESSED"` e o evento histórico original; `receivedAt` não muda. A API não cria novo histórico nem novos alertas.

Para **`eventId` usado com conteúdo divergente**, retorna **409**, preservando o registro original. Conteúdo idêntico é a combinação `deviceId`, `occurredAt` e `batteryLevel`, comparada após a normalização dos instantes (por exemplo, `-03:00` e `Z` equivalentes). A API rejeita datas futuras.

**201 de evento não afirma que um alerta foi aberto:** um evento normal pode não gerar ocorrência e um evento antigo só entra no histórico.

### 4.3 Listas, detalhes e filtros

Exemplo de paginação em listagem:

```json
{
  "data": [],
  "meta": {"page":1,"pageSize":20,"totalItems":0,"totalPages":0}
}
```

O exemplo mostra uma lista vazia: não é erro de recurso inexistente. Um **UUID inválido** em caminho, filtro ou paginação gera **400**; um dispositivo inexistente no caminho de detalhes/histórico gera **404**. Filtrar `/alerts?deviceId=` com UUID válido mas não cadastrado retorna lista vazia, e não necessariamente 404.

Em alertas, `status` aceita `OPEN` ou `RESOLVED`, **derivado de `resolvedAt`**; `acknowledged` aceita `true` ou `false`, **derivado de `acknowledgedAt`**. Isso permite consultar, por exemplo, ocorrências resolvidas sem reconhecimento.

### 4.4 Reconhecer alerta

```http
POST /api/v1/alerts/a15bef2e-41e2-44e0-ac70-d334f3ef7a3c/acknowledge
```

Resposta **200** inclui o alerta atualizado, em que `acknowledgedAt` é preenchido e `resolvedAt` continua `null` se a falha permanecer.

Uma segunda tentativa, enquanto o alerta ainda está aberto e já reconhecido, retorna **200** sem alterar a data do primeiro reconhecimento. Se o alerta já estiver resolvido, retorna **409**, **mesmo que possua reconhecimento anterior**. Recurso inexistente retorna **404**.

O endpoint não aceita uma data escolhida pelo operador: o servidor registra o horário. A resolução continua **automática**, sem botão ou endpoint `resolve` no MVP.

### 4.5 Dashboard

```http
GET /api/v1/dashboard/summary
```

Resposta de exemplo:

```json
{"data":{
  "totalDevices":10,
  "onlineDevices":7,
  "offlineDevices":2,
  "noDataDevices":1,
  "openAlerts":3,
  "openAcknowledgedAlerts":1,
  "openUnacknowledgedAlerts":2
}}
```

**Invariantes:** `totalDevices = onlineDevices + offlineDevices + noDataDevices`; `openAlerts = openAcknowledgedAlerts + openUnacknowledgedAlerts`. Uma atualização do dashboard apenas **consulta** o backend, sem executar o verificador offline no browser.

## 5. Matriz de códigos HTTP e erros

| Situação | HTTP | error.code ou resultado | Efeito |
| --- | --- | --- | --- |
| Cadastro bem-sucedido | **201** | `data` com novo dispositivo | Dispositivo começa SEM_DADOS |
| Código de dispositivo já cadastrado | **409** | `DEVICE_CODE_CONFLICT` | Nenhum segundo dispositivo |
| Corpo malformado/campo obrigatório inválido | **400** | `VALIDATION_ERROR` | Não grava dados |
| Consulta de recurso que não existe | **404** | `DEVICE_NOT_FOUND` ou `ALERT_NOT_FOUND` | Sem alteração |
| Evento novo atual | **201** | `APPLIED` | Grava histórico e avalia estados |
| Evento novo antigo/empatado | **201** | `HISTORY_ONLY` | Grava histórico, estado inalterado |
| `eventId` idêntico ao já gravado | **200** | `ALREADY_PROCESSED` | Não altera nada |
| `eventId` repetido com payload diferente | **409** | `EVENT_ID_CONFLICT` | Rejeita, preserva original |
| Alerta reconhecido ou reconhecimento repetido enquanto aberto | **200** | `data` do alerta | Reconhecimento persistido uma vez |
| Tentativa de reconhecer alerta já resolvido | **409** | `ALERT_ALREADY_RESOLVED` | Nenhuma alteração |
| Parâmetro de filtro ou paginação inválido | **400** | `VALIDATION_ERROR` | Não executa a consulta |
| Erro inesperado do backend | **500** | `INTERNAL_ERROR` | Não confirmar sucesso |
| Banco ou serviço indisponível | **503** | `SERVICE_UNAVAILABLE` | Não confirmar sucesso; tentar novamente de maneira controlada |

**Decisão DP-010 proposta:** distinguir **500** para falha inesperada e **503** para indisponibilidade temporária conhecida do banco. Os BPMNs anteriores apresentavam 500 genericamente para erro interno; a semântica de tratamento (não confirmar gravação falsa) permanece a mesma. Após aprovação, esse refinamento passa a prevalecer nos contratos HTTP e deve ser considerado nos testes.

Formato de erro padronizado:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Revise os campos enviados.",
    "details": [
      {"field":"batteryLevel","message":"Deve estar entre 0 e 100."}
    ]
  }
}
```

Não divulgar stack trace, SQL, token, segredo ou string de conexão na resposta. Campos `details` podem ser vazios; `requestId` é opcional para correlação com logs.

## 6. Validações de entrada

| Campo | Validação |
| --- | --- |
| `code` | Texto de 1–50 caracteres, letras/números/`_`/`-`; normalizado em maiúsculas. |
| `name` | Texto com conteúdo não branco, até 120 caracteres; espaços laterais removidos. |
| `eventId` | UUID global do evento, obrigatório. |
| `deviceId` / `alertId` | UUID bem formatado; recursos devem existir para operações sobre eles. |
| `occurredAt` | RFC 3339 com `Z` ou deslocamento explícito `±HH:MM`; não pode ser futuro em relação ao backend. |
| `batteryLevel` | **Inteiro** de 0 a 100, compatível com SMALLINT no DP-009. |
| `page` / `pageSize` | Inteiros positivos; `pageSize` máximo 100; erros são 400. |
| Filtro `connectivityStatus` | SEM_DADOS, ONLINE ou OFFLINE. |
| Filtros `status` / `alertType` | OPEN/RESOLVED; LOW_BATTERY/NO_COMMUNICATION. |
| Filtro `acknowledged` | Booleano true/false, separado do status de resolução. |

Usar validação de entrada no backend e constraints do PostgreSQL. Verificações dinâmicas como data futura, timeout de 300 s e concorrência exigem serviços/transações, não apenas esquemas de JSON.

## 7. Transações, concorrência e segurança

- Ingestão: confirmar transação para evento + atualização de estado e alertas. `eventId` é único; replay idêntico devolve o registro persistido sem alterar `receivedAt`.
- Evento com mesmo `occurredAt` ou mais antigo: registrar apenas no histórico; não criar ou resolver alerta.
- Abertura de alerta: respeitar o índice parcial único de `alerts(device_id, alert_type)` para `resolved_at IS NULL`.
- Reconhecimento: atualização condicional a `resolved_at IS NULL`, protegida contra concorrência com resolução automática.
- Erro de infraestrutura: retornar 503 quando há indisponibilidade conhecida; 500 para inesperados, registrando apenas detalhes seguros.
- Em operações não confirmadas, a API não garante que o produtor conheça se houve persistência antes de perder a resposta: **reenvio do mesmo `eventId`** torna a ingestão segura contra duplicação.
- Desenvolvimento local sem autenticação. **É proibido expor livremente operações de escrita em demonstração pública** sem controles e análise de segurança (ADR-005).

## 8. Casos de teste contratuais propostos

| ID | Cenário | Resposta esperada |
| --- | --- | --- |
| API-01 | POST devices válido | 201, UUID e SEM_DADOS |
| API-02 | POST devices com code já cadastrado | 409, DEVICE_CODE_CONFLICT |
| API-03 | GET devices com q e filtro | 200 e lista paginada |
| API-04 | GET devices com pageSize >100 | 400 |
| API-05 | GET device inexistente | 404 |
| API-06 | GET histórico com vários eventos | 200, ordenação e meta |
| API-07 | POST events válido com bateria 20 | 201 APPLIED, pode abrir alerta |
| API-08 | POST events igual ao anterior | 200 ALREADY_PROCESSED, sem mutação |
| API-09 | POST events com eventId igual e bateria diferente | 409 EVENT_ID_CONFLICT |
| API-10 | POST events antigo, identificador novo | 201 HISTORY_ONLY, estado e alertas inalterados |
| API-11 | POST events com data futura | 400 VALIDATION_ERROR |
| API-12 | POST events deviceId inexistente | 404 DEVICE_NOT_FOUND |
| API-13 | POST events batteryLevel 101 | 400 VALIDATION_ERROR |
| API-14 | GET alerts?status=OPEN&acknowledged=false | 200 com filtros independentes |
| API-15 | GET detalhe de alerta | 200 ou 404 |
| API-16 | POST acknowledge de alerta aberto | 200 sem resolver |
| API-17 | Repetir acknowledge em alerta aberto | 200 idempotente |
| API-18 | POST acknowledge em alerta resolvido | 409 ALERT_ALREADY_RESOLVED |
| API-19 | GET dashboard summary | 200 com totais coerentes |
| API-20 | Banco indisponível | 503 sem sucesso falso |
| API-21 | Reenvio após resposta incerta por falha | 200 idempotente ou 201 nova inserção, jamais duplicado |

**Testes ainda não executados.** Eles servem de base ao DP-012 e à implementação. Nenhuma rota de produção foi criada neste card.

## 9. Revisão e aceite

- [ ] Todas as ações previstas de interface/simulador estão mapeadas a uma operação ou processo interno.
- [ ] As nove operações OpenAPI cobrem cadastro, busca, filtros, detalhes, histórico, ingestão, alertas, reconhecimento e dashboard.
- [ ] Esquemas e exemplos JSON são coerentes com UUID, colunas e relacionamentos do DP-009.
- [ ] Reenvio idêntico, conflito de identidade e evento fora de ordem têm respostas diferentes.
- [ ] Reconhecimento de alerta não se confunde com resolução automática.
- [ ] Paginação, campos obrigatórios e validações de entrada são explícitos.
- [ ] Erros 400/404/409/500/503 possuem estrutura padronizada.
- [ ] Simulador consome a mesma API que recebe eventos; sem acesso direto ao banco.
- [ ] Sem auth no MVP, decisões de segurança para publicação estão documentadas.
- [ ] O OpenAPI é inspecionado por validador/visualizador; não declarar esse critério cumprido sem evidência.
- [ ] Documento e contrato aprovados antes do merge na `main`.

**Próxima etapa:** DP-011 — UX/UI e especificação das interfaces.

---

*Contrato proposto para projeto de portfólio com dados fictícios. Os endereços, UUIDs e horários são exemplos e não demonstram uma API em execução.*
