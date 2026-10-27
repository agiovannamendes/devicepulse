# DP-012 — Plano de testes, segurança e rastreabilidade

**Versão:** 0.1  
**Situação:** Rascunho para revisão e aprovação documental  
**Projeto:** DevicePulse — sistema de monitoramento de dispositivos fictícios  
**Card:** DP-012  
**Dependências aprovadas:** [DP-003 — RF e RNF](03-requisitos-funcionais-e-nao-funcionais.md), [DP-004 — regras e estados](04-regras-de-negocio-e-estados.md), [DP-010 — API/OpenAPI](10-contratos-rest-openapi.md) e [DP-011 — wireframes e fluxos](11-wireframes-fluxos-interfaces.md).  
**Referências adicionais:** [DP-007 — exceções](07-validacao-bpmn-e-matriz-excecoes.md), [DP-008 — arquitetura](08-arquitetura-c4-fluxo-dados.md), [DP-009 — modelo PostgreSQL](09-modelo-dados-e-dicionario.md).

## 1. Objetivo e princípio de aceite

Definir **antes de implementar** como comprovar que o MVP atende aos requisitos e regras de negócio, quais riscos devem impedir a liberação e que evidências serão exigidas. O plano contempla validação unitária, integração com API e PostgreSQL, verificador periódico, UX ponta a ponta, desempenho, segurança, privacidade e reprodutibilidade.

**Este documento é planejamento de QA, não relatório de execução.** Neste momento não existem evidências de testes do sistema em funcionamento: **todos os casos estão `NÃO_EXECUTADO`**. A aprovação do card aprova a estratégia e a matriz para orientar a implementação, mas **não** atesta a qualidade de uma aplicação ainda não desenvolvida.

## 2. Artefatos entregues

| Artefato | Propósito |
| --- | --- |
| [12-casos-teste.csv](qa/12-casos-teste.csv) | Catálogo de **79 casos**, com níveis, prioridade, pré-condição, ação, resultado, RF/RN/RNF, exceções, endpoint, tela, status e campos para evidências/issues |
| [12-matriz-rastreabilidade.csv](qa/12-matriz-rastreabilidade.csv) | Relação entre os **20 RF, 23 RN e 12 RNF**, cada um apontando para pelo menos um caso planejado |
| [12-checklist-seguranca.md](qa/12-checklist-seguranca.md) | **20 verificações SEC-01 a SEC-20** com prioridades e critérios de segurança e privacidade |
| [12-ambiente-massa-e-execucao.md](qa/12-ambiente-massa-e-execucao.md) | Estratégia de ambiente de teste, fixtures fictícias, relógio controlado, medição de desempenho e evidências |
| Este documento | Estratégia, escopo, prioridades, riscos, responsabilidades, critérios de saída e pendências de validação |

Os CSVs usam UTF-8 e delimitador vírgula, com campos entre aspas; podem ser lidos no VS Code, planilha ou scripts de teste. O campo `status` deverá ser atualizado nas futuras execuções, nunca preenchido como PASSOU por suposição.

## 3. Cobertura e métricas documentais

| Dimensão | Quantidade | Resultado da preparação |
| --- | ---: | --- |
| Casos QA-001..QA-079 | **79** | Planejados, sem execução |
| Casos P0 | **73** | Bloqueiam aceite funcional quando não passam |
| Casos P1 | **6** | Importantes; falhas exigem triagem e decisão |
| RF-001..RF-020 | **20/20** | Todos vinculados a um ou mais testes |
| RN-001..RN-023 | **23/23** | Todos vinculados a um ou mais testes |
| RNF-001..RNF-012 | **12/12** | Todos vinculados a um ou mais testes |
| EX-01..EX-27 do DP-007 | **27/27** | Todos ligados a pelo menos um teste |
| Checklist SEC-01..SEC-20 | **20** | Todos pendentes de execução |

**Cobertura documental não significa aprovação de execução**: os vínculos estabelecem *o que será testado*, não que os resultados esperados já foram observados.

## 4. Pirâmide e divisão de responsabilidades

| Nível / técnica | Objetivo | Principal responsável futuro | Exemplos da matriz |
| --- | --- | --- | --- |
| **Unitário** | Avaliar regra isolada, com relógio determinístico e sem dependência externa | Desenvolvedor backend | Limiar 20/21%, tempo 299/300/301 segundos, transições e normalização |
| **Integração/API** | Exercitar endpoints reais, validação, contratos e códigos HTTP | Backend / QA | Cadastro, paginação, POST events, reconhecimento, status 200/201/400/404/409/500/503 |
| **Integração/DB** | Garantir PK/FK, índices, rollback e transações concorrentes em PostgreSQL | Backend / QA | Idempotência global, histórico, unicidade do alerta aberto, FK de origem, concorrência |
| **Integração/Job** | Verificar o processo de detecção offline e retomada | Backend / QA | Simulador pausado, ciclo de 30 s, indisponibilidade e reconciliação |
| **E2E** | Simular a jornada real no navegador com API e banco integrados | Frontend / QA | Visão geral → cadastro → detalhes → alertas → reconhecer |
| **UX/acessibilidade** | Conferir linguagem, navegação, estados, teclado e telas responsivas | Frontend / QA | SEM_DADOS, falhas, 360 px, foco, rótulos textuais e feedback |
| **Segurança** | Verificar proteção de segredos, validação e limites de exposição | Todos; revisão de segurança antes de publicar | SQL parametrizado, ausência de credenciais, política de escrita pública |
| **Performance** | Medir RNF-004 em ambiente de demonstração | Backend / QA | 100 dispositivos e 10 mil eventos fictícios; respostas em até 2 s |
| **Documentação** | Verificar reprodutibilidade, automação e vínculo GitHub/Trello | Todos | README, seed, comandos e PRs com evidências |

A equipe poderá acumular essas responsabilidades no projeto de portfólio; a tabela define *papéis no processo*, não pressupõe pessoas ou equipes contratadas.

## 5. Cenários críticos (P0)

### 5.1 Recebimento de eventos e histórico

- Payload ausente, UUID inválido, bateria fora de 0–100, horário sem fuso ou futuro ⇒ HTTP **400**; nada aplicado.
- Dispositivo não encontrado ⇒ **404**; nenhum evento órfão.
- `eventId` com conteúdo idêntico ⇒ **200 ALREADY_PROCESSED**, sem atualização de `receivedAt`, estados ou alertas.
- `eventId` repetido com dados divergentes ⇒ **409 EVENT_ID_CONFLICT**, preservando original.
- `eventId` novo com horário igual/anterior ao último aplicado ⇒ **201 HISTORY_ONLY**: guardar histórico, mas **não** alterar o estado atual ou alertas.
- Erro entre gravação do evento e tratamento de alertas ⇒ rollback consistente; não confirmar resultado parcial.

### 5.2 Limiares de bateria e comunicação

| Entrada | Resultado previsto |
| --- | --- |
| Bateria **20%** | `BAIXA` e alerta LOW_BATTERY, caso ainda não exista aberto |
| Bateria **21%** | `NORMAL` e resolução automática de LOW_BATTERY, se aplicável |
| Comunicação há **299 segundos** | `ONLINE` |
| Comunicação há **300 segundos** | `ONLINE` (limite ainda não ultrapassado) |
| Comunicação há **301 segundos** | `OFFLINE` e NO_COMMUNICATION quando o verificador avaliar |
| Dispositivo sem primeira medição | `SEM_DADOS`, sem alerta offline, independentemente de tempo desde o cadastro |
| Dispositivo offline com última bateria 15% | Ambos os alertas podem coexistir sem se anularem |
| Novo evento recente com bateria 15% | Comunicação volta ONLINE; alerta offline resolve, bateria baixa continua |

**Verificador:** checagem interna prevista a cada **30 segundos**. **Simulador:** envia normalmente a cada **60 segundos** por dispositivo. Usar relógio injetável e processo controlado para testar o limite sem esperar minutos reais; conferir agendamento em teste separado.

### 5.3 Ciclo dos alertas

- No máximo um alerta **ainda não resolvido** por dispositivo e tipo, inclusive com requisições concorrentes.
- Reconhecimento em alerta aberto ⇒ **200**, grava `acknowledgedAt` sem alterar `resolvedAt` nem o estado técnico.
- Reconhecimento repetido enquanto aberto ⇒ **200** sem alterar o primeiro horário.
- Reconhecimento de alerta resolvido ⇒ **409**, independentemente de reconhecimento anterior.
- Resolução automática sem reconhecimento ⇒ `resolvedAt` preenchido e `acknowledgedAt = null`; histórico preservado.
- Recorrência após resolução ⇒ nova ocorrência; **nunca** reutilizar ou apagar o alerta resolvido.

### 5.4 Falhas de infraestrutura e retomada

Executar falhas controladas ao **consultar**, **persistir** e **confirmar transações**, além da queda no verificador de comunicação e durante reconhecimento. A API usa **503** para indisponibilidade conhecida e **500** para erro inesperado; em nenhum caso deve declarar sucesso não confirmado.

Após recuperação, reavaliar estados e alertas pelo histórico válido; a reconciliação deve ser idempotente e não duplicar ocorrências. Quando uma resposta ao simulador for perdida, reenviar o **mesmo eventId**: a gravação poderá já existir (200 idempotente) ou ainda não existir (201), mas **nunca duplicar**.

## 6. API, UX e fim a fim

O contrato OpenAPI aprovado lista **nove operações REST**. Os casos devem conferir o corpo JSON de sucesso (`data`, `meta` quando listado), esquema de erro (`error.code/message/details`), status HTTP e ausência de segredos. O backend é fonte oficial dos estados; o React mostra a resposta e a atualiza por GET, sem criar regras técnicas paralelas.

A automação E2E deve percorrer:
1. Abrir **Visão geral** e ler indicadores;
2. Abrir **Dispositivos**, buscar e filtrar, depois criar um dispositivo;
3. Confirmar a exibição de **Aguardando dados** antes da primeira medição;
4. Receber medição fictícia pelo simulador e atualizar a interface;
5. Consultar **Detalhes** e **Histórico** com paginação;
6. Abrir **Central de alertas**, selecionar uma ocorrência ativa e **Reconhecer**;
7. Confirmar que a ocorrência continua tecnicamente aberta, até normalização automática;
8. Simular falhas 400/404/409/500/503 e verificar feedback sem falso sucesso;
9. Repetir no mobile, com pelo menos uma verificação em **360 px**.

**Não testar login, alteração manual de status, controle visual do simulador ou botão de resolução**, pois tais funções não foram aprovadas no MVP.

## 7. Segurança e privacidade

Aplicar o [checklist SEC-01 a SEC-20](qa/12-checklist-seguranca.md). São riscos especialmente críticos: segredo versionado, dados reais, SQL não parametrizado, endpoint de escrita aberto na internet sem proteção e operação que quebre integridade transacional.

A demonstração do projeto é **local por padrão**, sem autenticação no MVP. Caso haja plano de hospedagem pública, exigir análise de acesso/segurança antes da publicação. O CORS não substitui autenticação e HTTPS não impede, sozinho, abuso de endpoints de escrita.

## 8. Desempenho e reprodutibilidade

Conforme **RNF-004**, medir em ambiente local documentado, com **até 100 dispositivos fictícios e 10.000 eventos artificiais**, sob **uma requisição por vez**. Consultas de indicadores e listagens paginadas devem responder em **até 2,0 segundos cada**.

O método de medição adotará:
- Carga determinística, ambiente e versão/commit registrados;
- Dez requisições sequenciais por rota representativa (dispositivos, histórico, alertas e dashboard), registrando **todos** os tempos;
- Critério de aceite: **nenhuma** das respostas avaliadas excede 2.000 ms; relatar máximo além de médias;
- Separar tempo de geração da massa do tempo de consulta;
- Medir somente quando a API e o banco estiverem implementados; não inventar benchmarks na fase documental.

A estratégia de preparação, clock controlado, seeds e evidências está em [Ambiente e execução](qa/12-ambiente-massa-e-execucao.md).

## 9. Gestão de defeitos, evidências e portões

### Antes da implementação — portão DP-013

Para aprovar a especificação como base de desenvolvimento:
- RF/RN/RNF e EX possuem testes associados;
- Os artefatos de QA estão rastreáveis e sem contradições graves com BPMN, DER, OpenAPI e wireframes;
- As restrições e riscos P0 são conhecidos, com tratamento planejado;
- Pendências técnicas do pacote de especificação estão documentadas e atribuídas;
- Conferir **visualmente** os cinco BPMNs do DP-005/006/007 no BPMN.io, ainda não evidenciado;
- Inspecionar OpenAPI 3.1 em **validador/visualizador independente**, ainda não comprovado;
- Revisar os wireframes em visualizador/browser e confirmar responsividade efetiva durante a implementação (mobile em SVG de 390 px; alvo 360 px).

**A aprovação do DP-012 aprova somente o plano**. O DP-013 revisará se o pacote está pronto para iniciar o código, sem exigir testes funcionais de uma aplicação inexistente.

### Durante implementação — portão funcional

- Todos os **P0 aplicáveis** devem estar **PASSOU** para declarar MVP apto a entrega, sem falhas abertas severas;
- Uma falha P0 bloqueia a entrega; se um P0 for realmente inaplicável, exigir justificativa documentada, revisão do critério e evidência;
- Falhas P1 são registradas e priorizadas; não podem ser ocultadas como PASSOU;
- Testes automáticos de unidade/integração e regressão executam nas alterações relevantes;
- Testes de segurança P0 e desempenho RNF-004 precisam de evidências reproduzíveis;
- Falhas e correções são ligadas a issues, cards ou PRs.

### Evidência por execução

Cada caso possui `status`, `evidence` e `issue` no catálogo CSV. Ao executar, registrar ainda ambiente, data, commit, comando, logs sanitizados e resultado observado em artefato associado. Status permitidos: **NÃO_EXECUTADO, PASSOU, FALHOU, BLOQUEADO, NÃO_APLICÁVEL (justificado)**.

Relatar como **BLOQUEADO**, e não como PASSOU, caso o banco, frontend, simulador ou verificador necessário ao teste ainda não exista.

## 10. Principais riscos e mitigação

| Risco | Probabilidade/impacto qualitativos | Mitigação proposta |
| --- | --- | --- |
| Evento duplicado corromper estado | Média / Alto | eventId global, índice único e testes de replay |
| Evento atrasado regressar estado | Média / Alto | Verificação temporal estrita e transação |
| Alerta aberto duplicado sob concorrência | Média / Alto | Índice único parcial, bloqueios e testes concorrentes |
| Falha do banco provocar sucesso falso | Média / Alto | 500/503, rollback, reconsulta e reconciliação |
| Reconhecimento após resolução | Média / Médio | UPDATE condicional e teste concorrente |
| Perda do verificador após reinício Node | Média / Alto | Retomada no próximo ciclo e monitoramento do processo |
| Escrita pública sem autenticação | Variável / Alto | Demo local padrão; proteção antes de qualquer publicação |
| Segredos ou dados reais no repositório | Baixa / Alto | Auditoria de Git e checklist SEC-01 a SEC-04 |
| UI confundir bateria e conectividade | Média / Médio | Rótulos independentes, estados SEM_DADOS e testes UX |
| Desempenho com 10 mil eventos | Média / Médio | Índices, paginação e benchmark sequencial de 2 s |

As classificações de risco são **propostas qualitativas**, não probabilidades medidas nem falhas já observadas.

## 11. Checklist para aprovação deste card

- [ ] Matriz RF/RN/RNF referencia ao menos um teste para cada ID aprovado.
- [ ] O catálogo inclui testes para as 27 exceções do DP-007.
- [ ] Casos unitários/integração/API/DB/job/E2E/segurança/UX e desempenho estão definidos.
- [ ] Bateria 20/21%, timeout 299/300/301 s, deduplicação e fora de ordem estão cobertos.
- [ ] Persistência, rollback, reconhecimento e resolução independentes estão cobertos.
- [ ] Checklist de segurança e prevenção de segredos preparado.
- [ ] Dados fictícios, ambiente de teste e método de medição RNF-004 definidos.
- [ ] Nenhum teste é declarado executado, e todos têm critério e campo de evidência.
- [ ] As pendências de validação final ficam explícitas para o DP-013.
- [ ] Aprovação documental do DP-012 antes de merge na `main`.

**Próximo card:** DP-013 — Revisar e aprovar a especificação antes de codificar.

---

*Este projeto documenta cenários fictícios e não utiliza equipamentos, eventos, contas ou credenciais reais.*
