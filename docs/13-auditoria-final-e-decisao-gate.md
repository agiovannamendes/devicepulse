# DP-013 — Relatório de auditoria final e decisão do portão

**Versão:** 0.1 (relatório para revisão, relativo ao pacote aprovado DP-001 a DP-012)  
**Situação do gate:** **PENDENTE / IMPLEMENTAÇÃO AINDA NÃO LIBERADA**  
**Data de referência:** 27/10/2026  
**Projeto:** DevicePulse — portfólio Full Stack com dispositivos e eventos exclusivamente fictícios  
**Card:** DP-013  
**PR:** rascunho; dependente de inspeção e aceite, sem merge automático.

## 1. Objeto e resultado da auditoria

Esta auditoria cruza escopo, casos de uso, requisitos, regras, BPMNs, arquitetura C4, modelo PostgreSQL, contrato REST, wireframes e matriz de testes para impedir que diferenças de interpretação se transformem em código. O pacote antecedente **já possui aprovações documentais**, mas a decisão de liberação para implementação depende de **evidências específicas**.

**Resultado preliminar:** a estrutura documental e as regras centrais estão majoritariamente alinhadas; há correções editoriais aplicadas nesta branch e **pendências obrigatórias** de inspeção visual BPMN, alinhamento das legendas no modelador e validação independente OpenAPI. Portanto, **ainda não existe decisão definitiva de "GO"** e o MVP não foi congelado formalmente.

### 1.1 Evidências documentais conferidas

| Verificação | Resultado | Limitação |
| --- | --- | --- |
| DP-001 a DP-012, documentos principais | **12/12 disponíveis** na `main` com versionamento aprovado | Não equivale a aprovação do gate DP-013 |
| Vínculos relativos nos 12 documentos | **105 links internos verificados**, sem alvo ausente no inventário de arquivos | Verificação textual; links externos não foram testados |
| Cinco BPMNs | IDs únicos, fluxos/referências válidos, diagram interchange de formas/arestas, tags balanceadas no exame estrutural | **Ainda sem importação/inspeção dos cinco arquivos em BPMN.io neste card** |
| Modelo PostgreSQL | Três tabelas `devices`, `device_events`, `alerts`; 3 FKs, índice parcial para alertas abertos | DDL não executado em PostgreSQL; migrações começam em DP-015 |
| OpenAPI | Especificação 3.1 `info.version=1.0.0`, nove operações, 16 esquemas | Validação em ferramenta independente e HTTP real pendentes |
| Wireframes | 14 SVGs desktop/mobile e 3 fontes Mermaid vinculados ao Documento 11 | Revisão visual externa e teste real em 360 px pendentes |
| QA | 79 casos, 55/55 RF/RN/RNF e 27/27 exceções vinculados; 20 verificações SEC | Todos os casos funcionais continuam `NÃO_EXECUTADO` |
| Desenvolvimento | 24 cards previstos (DP-014 a DP-037), com DP-014 para iniciar monorepo | Nenhum card de código foi liberado nem marcado como executado |

**Nota de precisão:** a revisão estrutural de BPMN e de documentos não substitui a interpretação completa do modelador, teste de integração ou execução da aplicação.

## 2. Achados, ajustes e classificação

| ID | Severidade para o gate | Achado / risco | Ajuste ou ação prevista | Situação |
| --- | --- | --- | --- | --- |
| **G-01** | **Bloqueante** | Não há evidência da abertura e inspeção visual **dos cinco BPMNs** em BPMN.io: gateways, legendas, setas/mensagens, caminhos de erro, sobreposições e legibilidade | Importar cada `.bpmn`, registrar screenshot/resultado e corrigir XML/layout se necessário | **PENDENTE** |
| **G-02** | **Bloqueante** | Os BPMNs antigos rotulam falhas técnicas genericamente como **500**, enquanto DP-010 v1.0 distingue **503** para indisponibilidade conhecida e **500** para erro inesperado | DP-005/006/007 receberam ressalva e matriz HTTP alinhada nesta branch. **Ainda harmonizar rótulos dos arquivos BPMN no modelador e conferir as prévias correspondentes** | **PARCIAL** |
| **G-03** | **Bloqueante** | Não há evidência de validação do OpenAPI 3.1 em visualizador/validador independente | Importar `docs/api/10-openapi.json` no Swagger Editor ou ferramenta compatível, registrar resultado e corrigir erros reais | **PENDENTE** |
| **G-04** | **Revisão obrigatória** | Wireframes SVGs passaram em estrutura, mas a revisão visual de legibilidade, navegação e hierarquia não foi registrada | Abrir a galeria desktop/mobile (7 conjuntos) e registrar aceite ou correções visuais | **PENDENTE** |
| **G-05** | Editorial | DP-009 v1.0 ainda dizia que as decisões estavam “propostas” e que o contrato dependeria do DP-010, já aprovado | Documento 09 v1.1 e header de DDL atualizados na branch do gate | **CORRIGIDO NESTE PR** |
| **G-06** | Editorial | DP-005/006/007 preservavam descrições HTTP anteriores à aprovação do OpenAPI | Notas de precedência nos Documentos 05/06 v1.2 e harmonização na matriz DP-007 v1.1 | **DOCUMENTADO; XML PENDENTE EM G-02** |
| **G-07** | Escopo/backlog | DP-016 dizia “CRUD” e “consultar por código”, sugerindo rotas não aprovadas | Card DP-016 ajustado para POST/GET/listagem e detalhe por UUID, sem PUT/PATCH/DELETE ou GET por código | **CORRIGIDO NO TRELLO** |
| **G-08** | Pós-gate, não bloqueia escrita de código | SQL físico ainda não rodou, testes REST/QA não executados | Executar DP-015 e os testes nas tarefas de implementação, com evidências reais | **PLANEJADO** |
| **G-09** | Pós-gate, não bloqueia escrita de código | Protótipos mobile são 390 px, enquanto RNF-006 exige interface real a partir de 360 px | Testar implementação em 360 px em DP-031 e casos QA de acessibilidade | **PLANEJADO** |
| **G-10** | Pós-gate, não bloqueia escrita de código | Publicação pública sem autenticação é risco de alteração indevida | Manter demo local; qualquer exposição pública passa pelo SEC e DP-036 | **RESTRIÇÃO ATIVA** |

### Severidade e interpretação

- **Bloqueante:** proíbe encerrar DP-013 como “aprovado” e autorizar DP-014.
- **Revisão obrigatória:** precisa de inspeção/registro antes de fechar o gate; mesmo sem defeito demonstrado, ausência de evidência impede declarar aceite visual completo.
- **Editorial:** corrigível sem alterar requisitos, regras, persistência nem endpoints. Aplicado na branch de revisão; depende do merge da PR.
- **Pós-gate:** pode ser executado na implementação sem alegar conclusão antecipada.

## 3. Regras finais e fonte de verdade — sem novos requisitos

| Tema | Linha de base aprovada | Fonte |
| --- | --- | --- |
| Natureza dos dados | Apenas dispositivos/eventos fictícios; sem hardware real, GPS ou integrações proprietárias | DP-001 e DP-003 |
| Stack | React/Vite, Node/Express modular em processo único, PostgreSQL, simulador Node separado | DP-008 ADR-001..ADR-005 |
| Identidade | `devices.id` e `eventId` como UUID; `code` normalizado e único | DP-009 / DP-010 |
| Estado inicial | `SEM_DADOS`, exibido como **Aguardando dados**, sem alertas | DP-004 RN-007/014; DP-011 |
| Bateria baixa | `batteryLevel <= 20`; normal `>20` | DP-004 RN-012/013 |
| Comunicação | `ONLINE` se diferença `<=300 s`; `OFFLINE` somente se `>300 s` | DP-004 RN-008/009 |
| Periodicidade | Simulador nominal 60 s por dispositivo; verificador backend 30 s | DP-004 e DP-008 |
| Duplicação de evento | Mesmo `eventId` idêntico = 200 idempotente; conteúdo diferente = 409 | DP-004 RN-005, DP-010 |
| Evento atrasado | Aceito no histórico, não modifica estado/alertas | DP-004 RN-006, DP-010 |
| Alertas | Um aberto por dispositivo/tipo; LOW_BATTERY e NO_COMMUNICATION independentes | DP-004 RN-016..RN-023, índice único DP-009 |
| Reconhecimento | Só em alerta aberto; idempotente enquanto aberto; **não resolve**; depois de resolvido = 409 | DP-004 RN-019, DP-010 |
| Erros API | HTTP 400, 404, 409, 500 e 503; 503 conhecido/temporário e 500 inesperado | **DP-010 v1.0 prevalece sobre propostas HTTP dos BPMNs** |
| Interface | Visão geral, Dispositivos, Novo, Detalhes/Histórico, Alertas, Detalhe de alerta | DP-011 |
| Testes | 79 casos, P0 bloqueante no aceite funcional; nenhum PASSOU ainda | DP-012 |

**Precedência das fontes:** para estados e regras técnicas, DP-004; para estrutura de dados, DP-009; para rotas/respostas HTTP, **DP-010**; para apresentação e interações, DP-011; para validação, DP-012. Documentos DP-001..003 e fluxos BPMN anteriores fornecem contexto de negócio e **não substituem decisões técnicas finais**.

## 4. Verificação de cobertura do MVP e fronteira congelável

### Funcionalidades dentro do candidato a MVP 1.0

- Cadastrar dispositivos fictícios, listar, buscar/filtrar e consultar detalhes.
- Simular e receber medições JSON, armazenar histórico e lidar com idempotência/ordem temporal.
- Apurar conectividade e bateria, detectar offline sem novo evento.
- Abrir, reconhecer, normalizar e consultar alertas com histórico e sem duplicação de aberto.
- Dashboard com contagens e atualização periódica via GET.
- Interface responsiva, feedback de erro/vazio/carregamento, teste por teclado.
- PostgreSQL, scripts reprodutíveis, seed fictícia, testes automatizados e documentação de execução local.

### Excluído: mudanças de escopo exigem novo card/ADR

GPS, dados reais, integração proprietária, autenticação multiusuário, edição/exclusão de dispositivos, resolução manual de alertas, controladores do simulador na interface, mensageria distribuída, microserviços, notificações externas e WebSockets obrigatórios **não são necessários ao MVP**.

**Situação de congelamento:** *candidato a escopo congelado*. Não registrar “MVP congelado” formalmente até a aprovação do DP-013; depois, quaisquer mudanças devem receber justificativa, impacto em RF/RN/DER/API/UX/QA e revisão pelo procedimento de PR.

## 5. Backlog de implementação e critérios de entrada

Existem 24 cards DP-014..DP-037 no backlog de desenvolvimento. As três primeiras entregas são:

| Ordem | Card | Dependências | Entrega / condição de aceite |
| --- | --- | --- | --- |
| 1 | **DP-014 — Monorepo JS** | DP-000 + DP-013 | Preparar `frontend/`, `backend/`, `simulator/`, npm scripts, `.env.example`, `.gitignore`, README local sem segredos |
| 2 | **DP-015 — Banco PostgreSQL** | DP-009 + DP-014 | Migrações reproduzíveis, 3 tabelas, PK/FK/CHECK/índices, conexão local e testes básicos |
| 3 | **DP-016 — API de dispositivos** | DP-010 + DP-015 | POST /devices, GET /devices, GET /devices/{deviceId}; busca por `q` sem criar endpoint adicional |

**DP-017..DP-037:** validações, simulador, ingestão, regras e alertas, testes, frontend, CI, QA, execução local, documentação e demo opcional. Permanecem em backlog: dependências só são cumpridas quando os respectivos PRs forem revisados/mesclados.

### Procedimento obrigatório ao iniciar uma tarefa de implementação

1. Confirmar DP-013 aprovado, documento do gate atualizado para 1.0 e PR mesclada à `main`.
2. Atualizar `main` local e criar branch específica para o card.
3. Implementar apenas o escopo e endpoints do card, usando documentação já aprovada.
4. Testar alterações pertinentes e registrar evidências de execução (nunca inventar PASSOU).
5. Abrir PR para `main`; submeter à revisão; fazer merge apenas após aprovação.
6. Mover card Trello de andamento → revisão → concluído, mantendo comentário/link do PR.

## 6. Checklist do portão final — situação atual

| Verificação | Critério para concluir | Estado |
| --- | --- | --- |
| DP-001..DP-012 disponíveis e aprovados | Documentos íntegros em GitHub | **CONFERIDO** |
| Limites de escopo claros | Dentro/fora definido com referências | **CONFERIDO** |
| Regra ⇄ banco ⇄ API ⇄ UI ⇄ teste | Não haver divergência de comportamento não resolvida | **PARCIAL — G-02** |
| Atualizações editoriais coerentes | PR do DP-013 revisada | **EM REVISÃO** |
| Cinco BPMNs | Importação, mensagens, gateways, caminhos e legibilidade comprovados | **PENDENTE — G-01** |
| Contrato OpenAPI | Importação e validação independente comprovadas | **PENDENTE — G-03** |
| Wireframes | Visuais desktop/mobile aceitos | **PENDENTE — G-04** |
| Backlog de desenvolvimento | Cards ordenados, primeiro DP-014 condicionado ao gate | **CONFERIDO** |
| Testes, segurança e reprodutibilidade planejados | DP-012 aprovado; execução futura discriminada | **CONFERIDO** |
| Assinatura/aceite da responsável | Aprovação explícita para **liberar programação** | **PENDENTE** |

## 7. Decisão recomendada no momento

<escape>**DECISÃO DO GATE: NO-GO TEMPORÁRIO — NÃO LIBERAR IMPLEMENTAÇÃO.**</escape>

Motivos objetivos: G-01/G-02/G-03 ainda carecem de validação e/ou ajuste de BPMN; G-04 carece de inspeção visual; o presente PR precisa de revisão. **Não** se trata de rejeitar o projeto: o escopo, a arquitetura, o banco, o contrato e a matriz de QA já são a base madura para a fase seguinte.

### Para mudar a decisão para GO

1. Apresentar evidência da importação e verificação dos cinco BPMNs e corrigir eventuais problemas reais, inclusive rótulos HTTP 500/503 conforme contrato.
2. Validar o OpenAPI 3.1 em visualizador/validador independente e registrar resultado sem erros impeditivos.
3. Revisar visualmente os 14 wireframes (7 conjuntos desktop/mobile) e registrar aceite ou ajustes.
4. Rever/mesclar ajustes editoriais deste PR, atualizar este documento para **versão 1.0** com evidências e status corretos.
5. Obter aprovação explícita da responsável, registrar **GO**, mover DP-013 a concluído e somente então iniciar DP-014.

Os itens G-08/G-09 são entregáveis da implementação e **não exigem fingir** que PostgreSQL, React ou testes de sistema já foram executados neste gate.

## 8. Arquivos do pacote DP-013

- [Evidências de verificação e instruções](gate/13-checklist-evidencias.md)
- [Matriz de interfaces e regras](gate/13-matriz-cruzada.md)
- [Registro dos ajustes e decisões](gate/13-registro-ajustes.md)

---

*Relatório de auditoria documental pré-implementação, sem testes de execução do produto e sem aprovação automática do portão.*
