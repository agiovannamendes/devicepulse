# DevicePulse — Documento 04: Regras de Negócio e Estados

**Versão:** 0.1  
**Situação:** Proposta para revisão  
**Card:** DP-004  
**Referências:** DP-001, DP-002 e DP-003 (versões 1.0)

## 1. Objetivo

Estabelecer as regras pelas quais o DevicePulse recebe eventos fictícios, determina o estado operacional de um dispositivo e controla o ciclo de vida dos alertas.

As decisões deste documento servem de referência para os BPMNs, o modelo de dados, os contratos da API e os testes. Os valores de configuração são **propostas para o MVP**, não parâmetros de equipamentos reais.

## 2. Conceitos e limites

- **Dispositivo:** equipamento eletrônico fictício cadastrado para monitoramento.
- **Evento:** informação simulada enviada ao backend, contendo identificador do evento, dispositivo, instante da ocorrência e nível de bateria.
- **Última comunicação válida:** horário do evento mais recente aceito para determinar o estado do dispositivo, considerando o momento em que ocorreu.
- **Estado de comunicação:** `SEM_DADOS`, `ONLINE` ou `OFFLINE`.
- **Estado de bateria:** `SEM_DADOS`, `NORMAL` ou `BAIXA`.
- **Alerta:** ocorrência operacional de bateria baixa ou ausência de comunicação.
- **Reconhecimento:** operador registra que tomou ciência de um alerta.
- **Resolução:** sistema registra que a condição geradora do alerta deixou de existir.

**Separação importante:** o estado de comunicação não substitui o estado de bateria. Um equipamento pode estar offline e, ao mesmo tempo, ter um último valor conhecido de bateria baixa. Nesse caso, as ocorrências podem coexistir.

## 3. Parâmetros propostos

| Parâmetro | Valor inicial proposto | Uso |
| --- | --- | --- |
| `LOW_BATTERY_THRESHOLD` | **20%** | Considerar bateria baixa quando o percentual for menor ou igual ao limite. |
| `COMMUNICATION_TIMEOUT_SECONDS` | **300 segundos (5 minutos)** | Identificar falta de comunicação após exceder o período. |
| `COMMUNICATION_CHECK_INTERVAL_SECONDS` | **30 segundos** | Frequência de execução do verificador interno. |

Os parâmetros ficarão na configuração da aplicação, com valores padrão documentados. **Não haverá tela para alterá-los no MVP.** Eles poderão ser ajustados antes da aprovação deste documento.

O instante exato da transição para offline poderá ter um atraso de até um ciclo do verificador, pois a análise é periódica.

## 4. Regras de cadastro e entrada de eventos

### RN-001 — Identidade do dispositivo
Cada dispositivo possui um identificador único e obrigatório. Não é permitido cadastrar outro dispositivo com o mesmo identificador.

### RN-002 — Identidade do evento
Cada evento produzido pelo simulador possui um identificador único, associado ao dispositivo. O backend utiliza essa identificação para evitar gravação e processamento repetidos.

### RN-003 — Campos mínimos do evento
Para processamento, o evento deve informar:
- `eventId`: identificador único do evento;
- `deviceId`: identificador de dispositivo cadastrado;
- `occurredAt`: instante da ocorrência, em ISO 8601 com fuso explícito;
- `batteryLevel`: percentual numérico de bateria de 0 a 100.

Os nomes finais dos campos serão confirmados no contrato de API (DP-010).

### RN-004 — Validação
Eventos com campos obrigatórios ausentes, dispositivo desconhecido, bateria fora do intervalo de 0 a 100, data inválida ou data de ocorrência posterior ao horário atual não podem alterar estados nem gerar alertas. A API deve informar o motivo da rejeição.

Para a primeira versão, o simulador usa o mesmo relógio de referência da aplicação, de modo a evitar dependência de sincronização de dispositivos físicos.

### RN-005 — Idempotência
Se o mesmo `eventId` for recebido novamente com dados idênticos, a operação deve ter resultado idempotente: não cria um novo evento de histórico, não altera o estado e não abre outro alerta.

Se um `eventId` já usado for enviado com conteúdo diferente, o backend rejeita o conflito sem sobrescrever o registro original.

### RN-006 — Eventos fora de ordem
O histórico pode guardar eventos válidos recebidos fora da ordem de ocorrência, mas **um evento com `occurredAt` igual ou anterior ao horário do último evento que define o estado não pode substituir o estado atual**.

Assim, a reentrega atrasada de uma medição não pode fazer o dispositivo voltar indevidamente a uma condição anterior nem resolver ou abrir alertas retroativos no MVP.

O sistema registra tanto o instante de ocorrência quanto o instante de recebimento, para permitir investigação da ordem temporal.

## 5. Regras de conectividade

### RN-007 — Estado inicial
Após o cadastro e antes de qualquer evento válido, o dispositivo fica em `SEM_DADOS`. Não é considerado online nem offline, e não recebe alerta de falta de comunicação apenas por estar recém-cadastrado.

### RN-008 — Estado online
Um dispositivo fica `ONLINE` quando existe comunicação válida e o tempo transcorrido desde `última comunicação válida` é **menor ou igual** a `COMMUNICATION_TIMEOUT_SECONDS`.

### RN-009 — Estado offline
Um dispositivo fica `OFFLINE` quando existe comunicação válida anterior e o tempo transcorrido desde ela é **maior** que `COMMUNICATION_TIMEOUT_SECONDS`.

O verificador interno executado periodicamente identifica a mudança, mesmo sem eventos novos.

### RN-010 — Recuperação da comunicação
Uma comunicação nova e válida, mais recente que a última considerada para o estado, pode devolver o dispositivo a `ONLINE`, desde que ainda esteja dentro do prazo de comunicação. Um evento atrasado não deve restaurar a conectividade.

### RN-011 — Avaliação no recebimento e no verificador
Após aceitar um evento novo, o backend reavalia a conectividade. O verificador periódico também reavalia todos os dispositivos que já se comunicaram. Dessa forma, a aplicação não depende de um evento para detectar a ausência de comunicação.

## 6. Regras de bateria

### RN-012 — Bateria baixa
Quando o evento mais recente considerado para o estado informa `batteryLevel <= LOW_BATTERY_THRESHOLD`, a bateria fica em `BAIXA`.

### RN-013 — Bateria normal
Quando o evento mais recente considerado para o estado informa `batteryLevel > LOW_BATTERY_THRESHOLD`, a bateria fica em `NORMAL`.

### RN-014 — Ausência de informação
Antes de receber medição válida, a bateria fica em `SEM_DADOS`. Esse estado não gera alerta de bateria baixa.

### RN-015 — Falta de comunicação não normaliza bateria
Se um dispositivo fica offline, sua última condição de bateria conhecida é preservada, com indicação de que a leitura pode estar desatualizada. O sistema não presume que a bateria voltou ao normal.

## 7. Regras e ciclo de vida de alertas

### RN-016 — Tipos de alerta
No MVP existem dois tipos: `LOW_BATTERY` e `NO_COMMUNICATION`. Cada alerta pertence a um dispositivo e possui registro de abertura, reconhecimento opcional e resolução opcional.

### RN-017 — Abertura de alerta
O sistema abre um alerta `LOW_BATTERY` quando a condição de bateria baixa está presente e não existe outro alerta aberto do mesmo tipo para o mesmo dispositivo.

O sistema abre um alerta `NO_COMMUNICATION` quando a condição offline está presente e não existe outro alerta aberto do mesmo tipo para o mesmo dispositivo.

### RN-018 — Exclusividade de alerta aberto
Para o mesmo dispositivo e tipo de alerta, pode existir **no máximo uma ocorrência ainda não resolvida**. Múltiplas ocorrências históricas resolvidas são permitidas.

A verificação da existência e a criação do alerta devem ser protegidas contra execuções concorrentes, por exemplo, por restrição/índice no banco e operação transacional.

### RN-019 — Reconhecimento
Um operador pode reconhecer uma ocorrência aberta. O sistema registra a data/hora do reconhecimento. No MVP, sem autenticação, não será registrada uma identidade verificável de usuário; o registro indica apenas que houve reconhecimento na demonstração.

Reconhecer um alerta **não** altera o estado técnico do dispositivo e **não** preenche a data de resolução. Reconhecimentos repetidos não devem criar novos eventos de reconhecimento.

### RN-020 — Resolução automática
O sistema resolve o alerta `LOW_BATTERY` quando uma medição nova válida indica bateria normal.

O sistema resolve o alerta `NO_COMMUNICATION` quando uma comunicação nova válida restaura a situação online.

O reconhecimento não é pré-condição para a resolução. Um alerta pode ser resolvido sem ter sido reconhecido.

### RN-021 — Preservação do histórico
A resolução registra a data/hora e encerra a ocorrência, sem excluí-la. Os campos de reconhecimento, se existirem, são preservados.

### RN-022 — Recorrência
Se a mesma condição voltar **depois da resolução**, uma nova ocorrência pode ser aberta para o dispositivo e tipo. Não se deve reabrir ou apagar o alerta histórico resolvido.

### RN-023 — Condições simultâneas
Se o dispositivo estiver offline e seu último estado conhecido de bateria for baixa, os dois tipos de alerta podem permanecer abertos ao mesmo tempo. Normalizar uma condição não resolve automaticamente a outra.

## 8. Tabelas de transição

### 8.1 Comunicação

| Estado anterior | Evento/condição | Próximo estado | Efeito nos alertas |
| --- | --- | --- | --- |
| SEM_DADOS | Nenhum evento válido | SEM_DADOS | Não abre alerta offline |
| SEM_DADOS | Primeira comunicação válida recente | ONLINE | Não abre alerta offline |
| SEM_DADOS | Primeiro evento válido já antigo | OFFLINE após avaliação | Abre alerta offline |
| ONLINE | Tempo desde última comunicação <= timeout | ONLINE | Mantém ausência de alerta offline |
| ONLINE | Tempo desde última comunicação > timeout | OFFLINE | Abre alerta offline |
| OFFLINE | Nenhuma comunicação válida recente | OFFLINE | Preserva alerta aberto |
| OFFLINE | Nova comunicação válida recente | ONLINE | Resolve alerta offline |
| Qualquer | Evento duplicado/fora de ordem | Sem mudança por esse evento | Sem mudança por esse evento |

**Observação:** a avaliação por tempo pode mudar o estado de conectividade independentemente de um novo evento.

### 8.2 Bateria

| Estado anterior | Evento novo válido | Próximo estado | Efeito |
| --- | --- | --- | --- |
| SEM_DADOS | 80% | NORMAL | Sem alerta |
| NORMAL | 20% | BAIXA | Abre alerta de bateria |
| BAIXA | 12% | BAIXA | Não duplica alerta |
| BAIXA | 21% | NORMAL | Resolve alerta de bateria |
| NORMAL | 19% | BAIXA | Abre nova ocorrência, se a anterior foi resolvida |
| Qualquer | Evento repetido/atrasado | Sem mudança por esse evento | Sem alteração de alerta |

### 8.3 Estados da ocorrência

Em vez de misturar reconhecimento com resolução em um único campo, uma ocorrência terá:

- `resolvedAt = null`: ocorrência **aberta**.
- `acknowledgedAt = null`: ocorrência **ainda não reconhecida**.
- `acknowledgedAt != null`: ocorrência **reconhecida**.
- `resolvedAt != null`: ocorrência **resolvida**.

Assim, as combinações possíveis são:

| Aberta? | Reconhecida? | Interpretação |
| --- | --- | --- |
| Sim | Não | Condição ativa, operador ainda não reconheceu |
| Sim | Sim | Condição ativa, operador já reconheceu |
| Não | Não | Condição normalizada sem reconhecimento prévio |
| Não | Sim | Condição normalizada depois de ter sido reconhecida |

A definição dos campos finais e eventuais dados de auditoria ocorrerá no DER (DP-009).

## 9. Exemplos operacionais e cenários de teste

| Código | Situação | Comportamento esperado |
| --- | --- | --- |
| CT-01 | Cadastro sem eventos | Comunicação e bateria SEM_DADOS, sem alertas |
| CT-02 | Primeiro evento recente com bateria 90% | ONLINE, bateria NORMAL, sem alerta |
| CT-03 | Bateria 20% | Bateria BAIXA, um alerta aberto |
| CT-04 | Repetição de bateria 20% em eventos novos | Mantém um alerta aberto, sem duplicação |
| CT-05 | Reenvio do mesmo eventId | Nenhuma gravação ou alteração adicional |
| CT-06 | Reenvio com mesmo eventId e payload diferente | Rejeita conflito e preserva dados |
| CT-07 | Bateria retorna para 21% | Resolve alerta de bateria mantendo histórico |
| CT-08 | Após resolução, bateria cai a 19% | Abre nova ocorrência |
| CT-09 | Passaram exatamente 300 segundos desde o evento | Ainda ONLINE na avaliação |
| CT-10 | Passaram mais de 300 segundos | OFFLINE e um alerta de comunicação |
| CT-11 | Verificador executa novamente sem comunicação | Não duplica alerta |
| CT-12 | Nova comunicação recente após offline | ONLINE e alerta de comunicação resolvido |
| CT-13 | Operador reconhece alerta aberto | Preenche reconhecimento, sem resolver |
| CT-14 | Condição normaliza antes do reconhecimento | Resolve o alerta mesmo sem reconhecimento |
| CT-15 | Dispositivo offline com bateria baixa | Duas ocorrências independentes |
| CT-16 | Evento atrasado enviado depois de outro mais recente | Pode constar no histórico, mas não reverte o estado nem alerta |
| CT-17 | Evento com bateria 101% ou dispositivo desconhecido | Rejeita e não altera estado |
| CT-18 | Evento com data futura | Rejeita e não altera estado |

## 10. Requisitos atendidos e próximos artefatos

| Regras | Requisitos principais | Destino |
| --- | --- | --- |
| RN-001 a RN-006 | RF-001, RF-005 a RF-008 | DP-005 BPMN, DP-009 banco, DP-010 API |
| RN-007 a RN-011 | RF-010, RF-011, RF-013 | DP-005/006 BPMN, DP-008 arquitetura |
| RN-012 a RN-015 | RF-009, RF-012 | DP-006 BPMN, DP-012 testes |
| RN-016 a RN-023 | RF-014 a RF-017 | DP-006/007 BPMN, DP-009 banco |

## 11. Decisões a validar neste card

1. O nível de bateria baixa será **20% ou menos**?
2. A comunicação será considerada perdida após **mais de 5 minutos** sem evento válido?
3. O verificador rodará a cada **30 segundos**, sujeito a ajustes técnicos de execução?
4. Dispositivos ainda sem eventos ficarão em **SEM_DADOS**, sem alerta?
5. O reconhecimento deve ser permitido somente enquanto o alerta está aberto?
6. Eventos atrasados serão preservados para consulta, mas não poderão alterar o estado atual?
7. A normalização resolverá automaticamente a ocorrência, inclusive se não houve reconhecimento?

**Não aprovar como versão 1.0 antes de validar essas decisões.**

---

*Documento de regras proposto para um sistema demonstrativo com dados fictícios. Não representa políticas operacionais de empresas ou dispositivos reais.*