# DP-012 — Checklist de segurança e privacidade

**Versão:** 1.0 — planejamento aprovado em 27/10/2026 (controles ainda não executados)  
**Ambiente-alvo:** desenvolvimento local e eventual demonstração pública condicionada à revisão de segurança.  
**Referências:** DP-003 RNF-001/002/003/012; DP-008 ADR-005; DP-010 REST/OpenAPI; DP-009 DER.

## Como usar

Para cada item, registrar: **PASSOU / FALHOU / BLOQUEADO / NÃO APLICÁVEL**, evidência (PR, log sanitizado ou captura com dados fictícios), data e issue corretiva. Antes de haver aplicação implementada, todos permanecem **PENDENTES**. Falha em item P0 impede a publicação pública; no MVP local também deve impedir o aceite quando representar risco direto para integridade/segredos.

| ID | Prioridade | Verificação objetiva | Critério para aprovar | Situação inicial |
| --- | --- | --- | --- | --- |
| SEC-01 | P0 | Inspecionar arquivos versionados, branches e histórico por tokens, senhas, chaves ou URLs com credenciais | Nenhum segredo real rastreado; se houver, revogar e corrigir histórico conforme risco | PENDENTE |
| SEC-02 | P0 | Confirmar `.gitignore` para `.env`, chaves, dumps e artefatos sensíveis | Arquivos locais confidenciais fora do Git | PENDENTE |
| SEC-03 | P0 | Verificar `.env.example`, sem valores secretos ou credenciais reutilizáveis | Só placeholders e defaults inofensivos; instruções claras de configuração | PENDENTE |
| SEC-04 | P0 | Auditar seeds, logs, screenshots, exemplos e documentação | Apenas identificadores e medições de dispositivos fictícios | PENDENTE |
| SEC-05 | P0 | Verificar que frontend e simulador nunca recebem credenciais PostgreSQL | Acesso ao banco somente pelo backend | PENDENTE |
| SEC-06 | P0 | Revisar queries, busca e filtros contra concatenação de SQL | SQL parametrizado, sem injeção com strings especiais | PENDENTE |
| SEC-07 | P0 | Exercitar campos obrigatórios, UUID malformado, datas futuras e bateria fora de 0–100 | HTTP 400 padronizado; nenhuma alteração de dados | PENDENTE |
| SEC-08 | P0 | Inspecionar tratamento 404, 409, 500 e 503 | Erros padronizados, sem stack trace, SQL ou detalhes internos ao cliente | PENDENTE |
| SEC-09 | P0 | Provocar falha transacional entre evento e alerta | Rollback ou consistência recuperável sem confirmação falsa | PENDENTE |
| SEC-10 | P0 | Disparar criação concorrente de alertas abertos | Unicidade parcial preservada por banco/transação | PENDENTE |
| SEC-11 | P0 | Disparar reconhecimento concorrente com resolução | Nunca preencher `acknowledgedAt` após resolver | PENDENTE |
| SEC-12 | P0 | Conferir origem de alertas LOW_BATTERY | `source_event_id` pertence ao mesmo dispositivo por FK composta | PENDENTE |
| SEC-13 | P0 | Avaliar acesso anônimo se houver hospedagem pública | **Sem operações de escrita públicas irrestritas**; adotar proteção ou permanecer local | PENDENTE |
| SEC-14 | P0 | Conferir HTTPS/TLS caso haja hospedagem pública | Não transmitir alterações ou tokens futuros por HTTP aberto | PENDENTE |
| SEC-15 | P1 | Conferir regras CORS antes de exposição externa | Origens explícitas; CORS não tratado como autenticação | PENDENTE |
| SEC-16 | P1 | Examinar dependências Node/npm e alertas críticos | Dependências fixadas/atualizadas ou riscos documentados e mitigados | PENDENTE |
| SEC-17 | P1 | Inspecionar entrada renderizada no React (nomes/códigos) | Sem `dangerouslySetInnerHTML` com conteúdo não confiável; saída segura | PENDENTE |
| SEC-18 | P1 | Verificar logs de erros e auditoria mínima | Sem payloads com dados sensíveis, senhas ou segredos; falha rastreável por requestId | PENDENTE |
| SEC-19 | P1 | Verificar política para tamanho do corpo e limites de requisições se a API for exposta | Controles adequados ao ambiente ou documentação de execução apenas local | PENDENTE |
| SEC-20 | P1 | Confirmar que dados de demo são isolados de ambientes reais | PostgreSQL de demonstração e configuração isolados de serviços terceiros | PENDENTE |

## Regras para decisão de implantação

1. **Somente local (padrão MVP):** não exige login; manter API de escrita acessível apenas no ambiente local/controlado e nunca publicar credenciais.
2. **Publicação externa somente leitura:** verificar origem dos dados, política CORS/HTTPS, ausência de segredos e controle de acesso aos endpoints de escrita.
3. **Publicação com escrita:** somente após decisão arquitetural explícita que adicione autenticação/autorização ou restrições equivalentes adequadas e proteção contra abuso. Está fora do MVP atual.
4. **Falha P0:** bloquear publicação até correção e reexecução com evidência. Não marcar controles como PASSOU por revisão documental isolada.

## Evidências mínimas de execução

Relatório dos comandos de auditoria do repositório (sem divulgar segredos), resultados de testes de API, saída de CI, registros SQL demonstrando rollback/unicidade, captura de configurações sem credenciais e link do PR corretivo. Os IDs SEC-01 a SEC-20 devem constar na revisão final do projeto e receber seus respectivos resultados.

**Status:** checklist **criado**, validações de segurança **não executadas**.
