# DevicePulse — Documento 02: Atores, Jornadas e Casos de Uso

**Versão:** 0.1  
**Situação:** Rascunho para revisão  
**Referência:** Documento 01 — Visão e Escopo do MVP  
**Card:** DP-002

## 1. Finalidade

Identificar quem interage com o DevicePulse, quais necessidades precisa atender e como essas interações se transformam em casos de uso verificáveis.

Este documento descreve **o comportamento esperado**, ainda sem especificar a implementação da API, do banco de dados ou das telas.

## 2. Contexto e participantes

O DevicePulse é um sistema demonstrativo de monitoramento de dispositivos **fictícios**. Uma aplicação simulará eventos; o sistema registrará informações e calculará situações; um operador consultará o painel e reconhecerá alertas.

| Participante | Papel | Interações previstas |
| --- | --- | --- |
| Operador | Usuário principal | Cadastrar e localizar dispositivos, consultar o painel e o histórico, reconhecer alertas. |
| Simulador de eventos | Sistema externo fictício | Enviar eventos periódicos de comunicação e níveis de bateria. |
| DevicePulse | Sistema sob desenvolvimento | Validar e armazenar eventos, determinar situações e gerenciar alertas. |
| Verificador de comunicação | Processo automatizado interno | Identificar dispositivos sem eventos recentes e acionar o tratamento previsto. |

**Limite do MVP:** o operador é um papel conceitual; não haverá login ou múltiplos perfis. O verificador de comunicação é um processo interno, **não** um segundo usuário.

## 3. Necessidades do operador

- Conhecer a quantidade de dispositivos cadastrados.
- Identificar rapidamente dispositivos sem comunicação ou com bateria baixa.
- Consultar detalhes e o histórico de cada dispositivo.
- Saber quais alertas estão ativos e quais já foram reconhecidos.
- Reconhecer uma ocorrência sem declarar que a falha técnica está resolvida.
- Localizar dispositivos por nome, código ou situação.

## 4. Jornada operacional proposta

A jornada é uma visão de alto nível: explica **o que ocorre ao longo do trabalho**, não cada chamada de API.

| Etapa | Quem atua | Acontecimento | Resultado esperado |
| --- | --- | --- | --- |
| 1. Cadastro | Operador | Registra um dispositivo fictício. | Dispositivo disponível para monitoramento. |
| 2. Geração de eventos | Simulador | Produz medição fictícia de bateria e comunicação. | Evento disponível para envio. |
| 3. Processamento | DevicePulse | Valida e armazena o evento. | Histórico atualizado e informação pronta para avaliação. |
| 4. Avaliação | DevicePulse | Aplica regras de bateria e conectividade. | Estado operacional e alertas atualizados. |
| 5. Acompanhamento | Operador | Consulta dashboard e detalhes. | Visão atual dos equipamentos e ocorrências. |
| 6. Reconhecimento | Operador | Registra ciência de um alerta. | Alerta marcado como reconhecido, ainda que a falha persista. |
| 7. Normalização | Simulador / DevicePulse | Uma condição volta ao normal e o sistema reavalia. | Resolução conforme regras, mantendo histórico. |

A ausência de comunicação pode ser detectada automaticamente por um verificador interno mesmo que o simulador não envie um novo evento.

## 5. Inventário de casos de uso

| ID | Caso de uso | Participante principal | Resultado |
| --- | --- | --- | --- |
| UC-001 | Cadastrar dispositivo | Operador | Dispositivo registrado. |
| UC-002 | Consultar e filtrar dispositivos | Operador | Lista de dispositivos encontrada. |
| UC-003 | Receber evento simulado | Simulador | Evento validado e processado. |
| UC-004 | Identificar ausência de comunicação | Verificador interno | Estado/alerta atualizado. |
| UC-005 | Visualizar dashboard | Operador | Indicadores e ocorrências exibidos. |
| UC-006 | Consultar histórico e detalhes | Operador | Eventos do dispositivo exibidos. |
| UC-007 | Reconhecer alerta | Operador | Ciência da ocorrência registrada. |
| UC-008 | Normalizar alerta | DevicePulse | Ocorrência resolvida conforme regra aplicável. |

## 6. Casos de uso detalhados

### UC-001 — Cadastrar dispositivo

**Participante principal:** operador.  
**Pré-condição:** sistema e banco disponíveis.

**Fluxo principal:**
1. O operador solicita o cadastro.
2. O sistema apresenta os campos necessários.
3. O operador informa um identificador e um nome.
4. O sistema verifica os dados e a unicidade do identificador.
5. O sistema registra o dispositivo.
6. O dispositivo passa a ser exibido na listagem.

**Exceções:** campos inválidos, identificador já cadastrado, falha de persistência.  
**Pós-condição:** dispositivo gravado sem duplicidade.

### UC-003 — Receber evento simulado

**Participante principal:** simulador de eventos.  
**Pré-condição:** dispositivo previamente cadastrado.

**Fluxo principal:**
1. O simulador envia um evento fictício para a API.
2. O sistema identifica o dispositivo.
3. O evento é validado.
4. O sistema armazena a informação.
5. As regras de estado e alertas são avaliadas.
6. A API responde com o resultado do processamento.

**Exceções:** dispositivo inexistente, percentual inválido, evento duplicado ou fora de ordem, indisponibilidade de armazenamento.

**Pós-condição:** dados coerentes e histórico preservado segundo regras ainda a detalhar.

### UC-004 — Identificar ausência de comunicação

**Participante disparador:** verificador interno (processo automatizado).  
**Pré-condição:** existe um dispositivo e um prazo máximo de comunicação configurado.

**Fluxo principal:**
1. O verificador consulta o horário da última comunicação considerada válida.
2. Compara o intervalo com o prazo definido.
3. Se o prazo foi ultrapassado, o sistema registra o estado offline.
4. Um alerta correspondente é criado ou atualizado, sem duplicar outro alerta ativo equivalente.
5. A situação passa a aparecer no painel.

**Exceções:** dispositivo ainda sem primeira comunicação, dados temporais inconsistentes ou falha de banco.  
**Pós-condição:** situação avaliada e registrada ou erro tratado.

### UC-007 — Reconhecer alerta

**Participante principal:** operador.  
**Pré-condição:** alerta existente e passível de reconhecimento.

**Fluxo principal:**
1. O operador acessa a central de alertas.
2. Seleciona um alerta.
3. Solicita o reconhecimento.
4. O sistema registra a ação e o momento da operação.
5. A interface atualiza a situação do alerta.

**Exceções:** alerta inexistente, repetição de ação ou falha na gravação.  
**Pós-condição:** ciência registrada; o problema pode continuar ativo.

## 7. Fluxos alternativos essenciais

**Bateria baixa:** um evento informa bateria inferior ou igual ao limite; o sistema gera alerta quando aplicável.

**Recuperação de bateria:** evento posterior informa valor normal; a regra de normalização atualiza o alerta e mantém o histórico.

**Perda de comunicação:** não chega evento dentro do prazo; o verificador registra a ausência, mesmo sem novo envio do simulador.

**Recuperação de comunicação:** evento válido chega depois da perda; o estado pode retornar ao normal, respeitando as regras temporais.

**Evento duplicado/atrasado:** o sistema identifica a situação e aplica a política definida em DP-004; não supor atualização automática do estado com qualquer evento recebido.

## 8. Fronteiras e responsabilidades

O **simulador** produz os dados de teste, mas não determina oficialmente que um dispositivo está offline ou que um alerta está resolvido.

O **backend DevicePulse** é responsável por validar os eventos, aplicar as regras de negócio e armazenar as mudanças.

O **frontend** exibe informações obtidas da API e permite ao operador solicitar ações; ele não deve calcular sozinho estados oficiais divergentes do backend.

O **operador** registra ciência de alertas; não controla o relógio de comunicação nem decide manualmente o resultado de validações técnicas.

## 9. Pontos pendentes para outras etapas

- Definição exata do timeout de comunicação: DP-004.
- Critérios completos de transição, deduplicação e resolução de alertas: DP-004.
- Modelagem formal dos fluxos e exceções: DP-005 a DP-007.
- Componentes internos e responsabilidades técnicas: DP-008.
- Banco de dados, contrato REST e telas: DP-009 a DP-011.

## 10. Critérios de revisão do DP-002

Este documento poderá ser aprovado quando:

- Os participantes e suas responsabilidades estiverem claros.
- Os casos de uso cobrirem as capacidades essenciais do MVP.
- Houver pelo menos um fluxo principal e um alternativo detalhado.
- A diferença entre reconhecer e resolver alertas estiver preservada.
- Não houver contradições com o Documento 01 ou inclusão indevida de funcionalidades.

### Perguntas para a revisão

1. Qual a diferença entre **participante**, **jornada** e **caso de uso**?
2. O operador consegue atualizar diretamente um dispositivo para online/offline?
3. Se um dispositivo deixar de enviar eventos, quem detecta o problema?
4. Reconhecer um alerta significa resolver a condição que o criou?

---

*Documento preparado para revisão. Nenhuma integração com dados reais ou plataformas proprietárias está prevista.*
