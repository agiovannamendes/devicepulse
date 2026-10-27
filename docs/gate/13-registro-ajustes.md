# DP-013 — Registro de ajustes e decisões da auditoria

**Versão:** 0.1 — histórico proposto para revisão  
**Status do gate:** ainda não aprovado; esta PR não libera implementação.

## 1. Ajustes produzidos no DP-013

| ID | Artefato / atividade | Antes | Depois / decisão | Limite da alteração |
| --- | --- | --- | --- | --- |
| AJ-01 | `docs/09-modelo-dados-e-dicionario.md` | v1.0: seção com decisões ainda “propostas” apesar do merge aprovado | **v1.1**: escolhas reconhecidas como aprovadas; contratos DP-010 citados como definitivos | Editorial, sem modificar schema |
| AJ-02 | `docs/dados/09-esquema-postgresql.sql` | Cabeçalho informava “PROPOSTA v0.1” | Cabeçalho indica referência documental aprovada v1.1 | Não executou DDL, não alterou SQL operacional |
| AJ-03 | `docs/05-bpmn-cadastro-ingestao.md` | v1.1 e explicações antigas de erro 500 | **v1.2**: nota de precedência ao DP-010 (503 indisponibilidade conhecida/500 inesperada) | XML BPMN e SVG **não editados**; ainda precisam de harmonização e revisão visual |
| AJ-04 | `docs/06-bpmn-alertas-reconhecimento-resolucao.md` | v1.1 e explicações antigas de erro 500 | **v1.2**: mesma nota do contrato definitivo | XML BPMN e SVG **não editados** |
| AJ-05 | `docs/07-validacao-bpmn-e-matriz-excecoes.md` | v1.0: códigos 500 anteriores ao contrato REST | **v1.1**: matriz EX-03/04/10/11/12/19 alinhada a HTTP 503 quando indisponibilidade conhecida, 500 inesperado | Não modifica regras e não afirma validação BPMN.io |
| AJ-06 | Trello **DP-016** | Texto “CRUD mínimo” e “consulta por ID/código” permitia extrapolação | Descrição esclarecida: `POST /devices`, `GET /devices` com `q`, `GET /devices/{deviceId}`. Nenhum PUT/PATCH/DELETE nem GET por código independente | Ajuste direto no card de backlog, sem código |
| AJ-07 | `docs/13-auditoria-final-e-decisao-gate.md` | Não existia | Registro da revisão, itens bloqueantes, fonte de verdade, congelamento candidato e decisão provisória | Sem autorização de início de implementação |
| AJ-08 | `docs/gate/13-checklist-evidencias.md` | Não existia | Plano explícito para importar cinco BPMNs, validar OpenAPI e inspecionar sete pares de wireframes | Evidências permanecem **PENDENTES** |
| AJ-09 | `docs/gate/13-matriz-cruzada.md` | Não existia | Matriz com nove operações do contrato e testes, e 13 invariantes centrais | Verificação documental; nenhum teste executado |

## 2. Divergências, sua precedência e decisão

**Diferença de representação HTTP em BPMN vs REST:** não alterar a semântica central (quando erro, nenhuma gravação falsa); a camada HTTP segue **DP-010 v1.0**. O XML BPMN precisará de atualização e validação de visualização antes do gate; a nota documental evita implementação incorreta enquanto o desenho é ajustado.

**Documentos de requisitos iniciais com “hipóteses” ou “próximos passos”:** são registros históricos de quando cada card foi produzido. A precedência atual é DP-004 para regras, DP-009 para esquema, DP-010 para REST, DP-011 para UX e DP-012 para QA. Não retirar o histórico de decisões de DP-001 a DP-003.

**Demonstração pública sem login:** aprova-se apenas execução local como padrão. Publicação pública com escrita requer revisão/decisão de segurança e não deve entrar implicitamente em DP-014.

**Limitações dos protótipos:** wireframes SVG foram validados estruturalmente, não funcionalmente; 390 px não é prova da meta real de 360 px. Testes de responsividade são responsabilidade da implementação/QA, com revisão visual documental no gate.

## 3. Pendências obrigatórias de encerramento

| ID | Ação | Responsabilidade da evidência | Critério para encerrar |
| --- | --- | --- | --- |
| PEND-01 | Importar cinco arquivos `.bpmn` no BPMN.io | Revisão do projeto | Resultado e screenshot por arquivo com gateways/fluxos/legibilidade |
| PEND-02 | Corrigir e inspecionar rótulos BPMN genéricos de 500 conforme OpenAPI | Revisão do projeto | XML e prévias coerentes, XML importável e nova inspeção visual |
| PEND-03 | Abrir e validar OpenAPI 3.1 independentemente | Revisão do projeto | Evidência de validador sem erros impeditivos |
| PEND-04 | Revisão visual dos 14 SVGs desktop/mobile | Revisão do projeto | Evidência de aceite/correções por conjunto |
| PEND-05 | Aprovar a PR de ajustes e registrar decisão de liberação | Responsável pelo projeto | Documento DP-013 v1.0, status GO fundamentado, PR mesclada e card concluído |

## 4. Controle de mudanças após o portão

Após futura decisão **GO**, o MVP passa a ser a baseline de implementação: novos RF, telas, entidades, rotas ou integrações exigem card próprio e avaliação do impacto em documentos técnicos, cenários de teste e esforço. Correções de defeitos para atender requisitos existentes são permitidas, mas precisam passar por PR e testes.

**Próximo card previsto:** DP-014 — preparar monorepo JavaScript e ferramentas, mas **não iniciar enquanto o gate estiver NO-GO**.

---

*Nenhuma atualização de versão ou checklist substitui evidência operacional real. Este registro evita que aprovações documentais anteriores sejam confundidas com o início efetivo da implementação.*
