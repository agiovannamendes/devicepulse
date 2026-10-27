# DP-013 — Checklist de evidências para revisão final

**Versão:** 1.0 — documento aprovado para referência; validações técnicas pendentes
**Estado da execução de verificações:** PENDENTE  
**Objetivo:** transformar avaliações externas em evidências objetivas, por arquivo, sem declarar validação que não foi realizada.

## A. BPMN.io — obrigatório antes do gate

**Ferramenta:** [BPMN.io Demo](https://demo.bpmn.io/). A visualização de SVG no GitHub não é substituto da importação do XML BPMN 2.0.

| ID | BPMN editável | Prévia correspondente | Abre em BPMN.io | Gateways/setas/mensagens e erros | Legibilidade | Evidência |
| --- | --- | --- | --- | --- | --- | --- |
| V-BPMN-01 | [05-cadastro.bpmn](../bpmn/05-cadastro.bpmn) | [SVG](../bpmn/05-cadastro.svg) | **PENDENTE NESTE GATE** | PENDENTE | PENDENTE | — |
| V-BPMN-02 | [05-ingestao.bpmn](../bpmn/05-ingestao.bpmn) | [SVG](../bpmn/05-ingestao.svg) | PENDENTE | PENDENTE | PENDENTE | — |
| V-BPMN-03 | [06-avaliacao-alertas.bpmn](../bpmn/06-avaliacao-alertas.bpmn) | [SVG](../bpmn/06-avaliacao-alertas.svg) | PENDENTE | PENDENTE | PENDENTE | — |
| V-BPMN-04 | [06-reconhecimento-alertas.bpmn](../bpmn/06-reconhecimento-alertas.bpmn) | [SVG](../bpmn/06-reconhecimento-alertas.svg) | PENDENTE | PENDENTE | PENDENTE | — |
| V-BPMN-05 | [07-retomada-operacional.bpmn](../bpmn/07-retomada-operacional.bpmn) | [SVG](../bpmn/07-retomada-operacional.svg) | PENDENTE | PENDENTE | PENDENTE | — |

**Procedimento por arquivo:**
1. Abrir BPMN.io, selecionar *Open Diagram* e carregar o XML do GitHub baixado em formato `.bpmn`.
2. Confirmar que nenhuma mensagem de erro de importação aparece.
3. Conferir visualmente fluxos de sequência, fluxos de mensagem (quando existirem), gateways, eventos de início/fim e saídas de validação/erro.
4. Conferir que texto, lanes, setas e rótulos não se sobrepõem e podem ser lidos.
5. **Verificar G-02:** ramos de falha conhecidos do banco devem estar consistentes com **503**, enquanto falhas inesperadas usam **500**. Se o desenho representa um erro genérico, evitar rotulá-lo como sempre 500. Ajustar o XML em editor BPMN, exportar novamente XML e prévia, revisar e registrar alterações.
6. Salvar screenshot ou link da evidência **sem informações reais de terceiros**, resultado (PASSOU / FALHOU / BLOQUEADO), data, versão do arquivo e eventual issue.

**Observação histórica:** o Documento 07 menciona abertura anterior de `05-cadastro.bpmn`; isso não dispensa documentar a revisão da versão atual no portão DP-013.

## B. OpenAPI 3.1 — obrigatório antes do gate

**Arquivo normativo:** [10-openapi.json](../api/10-openapi.json)

- [ ] Abrir a especificação em [Swagger Editor](https://editor.swagger.io/) ou visualizador compatível com OpenAPI 3.1.
- [ ] Confirmar `openapi: "3.1.0"`, `info.version: "1.0.0"`, 9 operações, schemas e referências resolvidas.
- [ ] Verificar `POST /events` nos casos 201 APPLIED, 201 HISTORY_ONLY, 200 ALREADY_PROCESSED e 409 conflito.
- [ ] Verificar `POST /alerts/{alertId}/acknowledge` 200 e 409 quando resolvido.
- [ ] Verificar status de erro 400/404/409/500/503, payload uniforme e paginação 1..100.
- [ ] Exportar screenshot/relatório de sucesso do validador, com data/versão e registrar se houver warnings.

**Validação interna já realizada anteriormente:** leitura JSON, verificação das referências locais e exemplos estruturalmente conferidos. **Ainda não é validação por ferramenta independente.**

## C. Wireframes e acessibilidade — revisão visual do pacote

**Galeria:** [Documento 11](../11-wireframes-fluxos-interfaces.md) e [exemplo SVG (Visão geral)](../ux/wireframes/11-overview-desktop.svg).

| Tela / estado | Desktop aberto | Mobile aberto | Hierarquia, navegação, estados | Evidência |
| --- | --- | --- | --- | --- |
| Visão geral | PENDENTE | PENDENTE | PENDENTE | — |
| Dispositivos | PENDENTE | PENDENTE | PENDENTE | — |
| Novo dispositivo | PENDENTE | PENDENTE | PENDENTE | — |
| Detalhes/histórico | PENDENTE | PENDENTE | PENDENTE | — |
| Central de alertas | PENDENTE | PENDENTE | PENDENTE | — |
| Detalhes de alerta | PENDENTE | PENDENTE | PENDENTE | — |
| Estados e feedback | PENDENTE | PENDENTE | PENDENTE | — |

- [ ] Texto claro, rótulos **Conectado**, **Sem comunicação**, **Aguardando dados**, **Reconhecido**, **Resolvido**.
- [ ] Reconhecer só aparece se a ocorrência está **aberta e ainda não reconhecida**.
- [ ] Estados de carregamento, sem dados, falha 400/404/409/500/503 possuem feedback apropriado.
- [ ] Exibição não depende exclusivamente de cor, especialmente bateria 20%, offline e alertas.
- [ ] Navegação desktop por menu lateral e mobile por área inferior; retorno funcional previsto.
- [ ] Desenhos SVG de **390 px** revisados visualmente. Teste funcional de React em **360 px** pertence à implementação, não é simulado aqui.

## D. Rastreabilidade, escopo e backlog — documentação

- [x] DP-001..DP-012 na `main`.
- [x] 105 links internos nos 12 documentos principais sem destino ausente no inventário.
- [x] 20 RF, 23 RN, 12 RNF e 27 EX com casos previstos.
- [x] Segurança SEC-01..SEC-20 planejada e não executada.
- [x] DP-014..DP-037 presentes no backlog; DP-014 deve iniciar apenas após gate.
- [x] DP-016 esclarecido para não gerar CRUD completo fora do OpenAPI.
- [ ] Corrigir todas as divergências antes de aprovar a implementação e revisar PR do DP-013.
- [ ] Registrar formalmente a decisão **GO** com aprovação explícita, caso todos os bloqueios sejam resolvidos.

## E. Registro final (não preencher antecipadamente)

| Campo | Valor atual |
| --- | --- |
| Resultado do gate | **NO-GO TEMPORÁRIO** |
| Responsável pelo aceite | **A definir no momento da aprovação explícita** |
| Data da aprovação | **PENDENTE** |
| Referências das evidências BPMN | **PENDENTE** |
| Evidência do validador OpenAPI | **PENDENTE** |
| Evidência visual wireframes | **PENDENTE** |
| Correções G-01..G-04 concluídas? | **NÃO** |
| Liberação formal DP-014 | **NÃO** |

> **Regra:** só atualizar a tabela depois de executar, inspecionar e registrar a evidência. Não declarar “aprovado”, “congelado” ou “implementação liberada” a partir de um checklist preenchido hipoteticamente.
