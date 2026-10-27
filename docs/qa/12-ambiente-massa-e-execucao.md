# DP-012 — Estratégia de dados de teste e execução reproduzível

**Versão:** 1.0 — plano aprovado; execução pendente  
**Projeto:** DevicePulse — exclusivamente cenários fictícios.

## 1. Ambiente mínimo da futura execução

- Node.js, frontend React, simulador e PostgreSQL configurados para **ambiente local de teste isolado**.
- Banco recriado/migrado em cada conjunto de integração, com dados artificiais controlados e **sem referências a equipamentos reais**.
- Relógio **injetável** nos serviços de regra para cenários de 299/300/301 segundos, sem esperar cinco minutos reais.
- IDs de dispositivos e eventos estáveis por teste, gerados localmente, para permitir repetição e comparar resultados.
- A suíte não deve reutilizar banco de desenvolvimento pessoal e jamais deve consultar dados externos.
- Simulador sob controle do teste: enviar, pausar, repetir com `eventId` idêntico, alterar bateria e produzir medição atrasada.

**Ferramentas a escolher durante implementação:** executor de testes unitários para Node.js, testes HTTP de integração com API e PostgreSQL real/isolado, testes e2e no navegador e verificador de acessibilidade. Não há dependências/frameworks já instalados por este documento.

## 2. Massa inicial recomendada

| Identidade (fictícia) | Estado antes dos testes | Uso |
| --- | --- | --- |
| `SENSOR_001` | Sem medição (`SEM_DADOS`) | Cadastro e primeiro evento |
| `SENSOR_002` | Evento mais recente com bateria 20 | Limite baixo e alerta LOW_BATTERY |
| `SENSOR_003` | Evento mais recente com bateria 21 | Fronteira normal/resolução |
| `SENSOR_004` | Evento mais recente com bateria 15 | Manutenção de alerta e offline simultâneo |
| `SENSOR_005` | Último evento com diferença exata de 300 s | Checar ainda ONLINE |
| `SENSOR_006` | Último evento com diferença de 301 s | Checar OFFLINE após ciclo |
| `SENSOR_007` | Alerta aberto e reconhecido | Repetição idempotente |
| `SENSOR_008` | Alerta resolvido, sem reconhecimento | Bloqueio de reconhecimento posterior |
| `SENSOR_009` | Eventos históricos T1, T2 | Chegada de evento novo com timestamp antigo |
| `SENSOR_010` | Histórico de alertas já resolvidos | Recorrência do mesmo tipo |

**Relógio de referência sugerido:** `2026-10-27T15:00:00Z` para as suítes com tempo congelado. Exemplo: medições em `T-300s` ainda estão dentro do prazo; em `T-301s` excederam o timeout. O verificador roda nominalmente a cada 30 segundos; testar separadamente seu agendamento e sua função de avaliação.

Os UUIDs técnicos de `devices.id`, `device_events.id` e `alerts.id` são gerados nos scripts de fixture. Cada reenvio do mesmo evento reutiliza o **mesmo UUID** e os mesmos dados canônicos. No reenvio conflitante altera-se apenas um campo mantendo `eventId`.

### Exemplos de entrada simulada

```json
{
  "eventId": "437bd4df-b1b2-41ef-b569-c6ac4ad1b46a",
  "deviceId": "184e54d0-09b4-45f5-bc23-b2b078b33e4f",
  "occurredAt": "2026-10-27T14:59:00Z",
  "batteryLevel": 20
}
```

**Esse JSON não é uma fixture aplicada**: ilustra o formato pactuado no DP-010. Para testes com data em função do relógio congelado, gerar automaticamente `occurredAt` a partir do `T` para não depender da data de execução.

## 3. Cenários temporais determinísticos

| Cenário | Relógio / evento | Resultado esperado |
| --- | --- | --- |
| Primeira medição | `T-60s` no dispositivo SEM_DADOS | ONLINE, bateria classificada |
| Intervalo menor | última comunicação `T-299s` | ONLINE |
| Fronteira exata | última comunicação `T-300s` | ONLINE |
| Fora do prazo | última comunicação `T-301s` | OFFLINE ao avaliar |
| Dispositivo sem evento | SEM_DADOS criado há mais de 300s | SEM_DADOS, sem alerta |
| Evento atrasado | último aplicado `T-60s` e novo id com `T-120s` | Histórico aumenta, estado não muda |
| Empate de horário | último aplicado e novo id em `T-60s` | Histórico aumenta, estado não muda |
| EventId repetido | replay idêntico de `T-60s` | 200 ALREADY_PROCESSED, sem novo histórico |
| EventId em conflito | replay de `T-60s` com nível diferente | 409 EVENT_ID_CONFLICT |
| Bateria baixa e offline | bateria 15 em `T-301s` | Alertas LOW_BATTERY e NO_COMMUNICATION independentes |
| Retorno de comunicação | evento novo válido em `T` com bateria 15 | Resolver apenas NO_COMMUNICATION |

## 4. Sequência de execução recomendada

1. **Unitários com relógio controlado:** bateria, timeout, transições de alerta, repetição e ordenação.
2. **Banco/integração:** aplicar migrações num PostgreSQL de teste descartável; testar FKs, CHECKs, índices parciais e rollback.
3. **Contrato/API:** executar chamadas reais às nove operações e validar corpo/status contra o OpenAPI 3.1.
4. **Job interno:** pausar simulador, avançar tempo e testar verificação, concorrência e reconciliação pós-falha.
5. **End-to-end React:** navegar desktop/mobile, cadastrar, filtrar, ver histórico, reconhecer e conferir feedback.
6. **Segurança e privacidade:** executar SEC-01..SEC-20 aplicáveis, com cuidados antes de qualquer demo pública.
7. **Desempenho:** sem concorrência, criar 100 dispositivos e 10.000 eventos artificiais, aquecer a aplicação, medir dez requisições sequenciais por rota representativa com tempos individuais e evidência do ambiente. **Cada** resposta de listagem paginada e de indicadores deve ser menor ou igual a 2.000 ms. Não transformar a meta em média ou percentil que oculte requisições lentas.
8. **Reexecução:** após correções, repetir casos afetados e teste regressivo P0.

## 5. Organização e evidência de execução

Adotar um artefato por execução, por exemplo `docs/qa/evidencias/<data>-<sha-abreviado>/`, contendo um arquivo de resumo, resultados sanitizados por teste e identificação do ambiente; **não** versionar dumps de banco, logs com segredos ou dados reais.

Campos mínimos por caso: `id`, `status` (**PASSOU, FALHOU, BLOQUEADO, NÃO_EXECUTADO**), `ambiente`, `commit`, `executadoEm`, `evidencia` e `issue`. Antes da implementação, toda a matriz de casos permanece como `NÃO_EXECUTADO`.

### Critério de regressão

Uma correção para `EX-15` (concorrência na abertura) deve reexecutar cenários de unicidade, recorrência, bateria baixa e timeout. Uma correção de ingestão deve reexecutar idempotência, fora de ordem, histórico e rollback. Uma alteração no contrato REST deve revalidar os exemplos OpenAPI, testes de status e as telas afetadas.

**Nenhum conjunto de teste foi executado nesta etapa documental.**
