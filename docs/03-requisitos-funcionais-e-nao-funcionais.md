# DevicePulse — Documento 03: Requisitos Funcionais e Não Funcionais

**Versão:** 0.1  
**Situação:** Rascunho para revisão  
**Card:** DP-003  
**Referências:** Documento 01 — Visão e Escopo (v1.0); Documento 02 — Atores, Jornadas e Casos de Uso (v1.0)

## 1. Objetivo

Definir de forma verificável **o que o DevicePulse deve fazer** e **quais condições de qualidade deve atender**. Os requisitos orientarão os processos BPMN, a arquitetura, o banco de dados, as APIs, as telas e os testes.

O sistema é uma aplicação demonstrativa de monitoramento de **dispositivos fictícios**. Não haverá integração com hardware real, rastreamento de pessoas ou infraestrutura proprietária.

## 2. Convenções

- **RF (requisito funcional):** comportamento que o sistema precisa oferecer.
- **RNF (requisito não funcional):** qualidade, restrição ou condição de operação do sistema.
- **Critério de aceitação:** observação objetiva que permite confirmar se o requisito foi atendido.
- **Prioridade P0:** essencial para considerar o MVP entregue.
- **Prioridade P1:** importante para a experiência completa do MVP, mas não impede demonstrar o fluxo básico enquanto estiver pendente.

**Importante:** regras de negócio detalhadas — como o tempo para considerar um dispositivo offline e a política de eventos atrasados — serão formalizadas em DP-004. Limiares mencionados aqui são preliminares.

## 3. Requisitos funcionais

| ID | Prioridade | Requisito | Critério de aceitação |
| --- | --- | --- | --- |
| **RF-001** | P0 | Cadastrar dispositivo fictício informando identificador único e nome. | Um cadastro válido fica persistido; identificador duplicado é rejeitado com mensagem clara. |
| **RF-002** | P0 | Listar os dispositivos cadastrados. | A listagem apresenta identificador, nome, estado de comunicação, bateria quando conhecida e última comunicação quando disponível. |
| **RF-003** | P1 | Pesquisar e filtrar dispositivos. | Busca por código/nome e filtro por situação retornam apenas os registros correspondentes. |
| **RF-004** | P0 | Consultar os detalhes de um dispositivo. | Ao selecionar um item, o operador visualiza suas informações atuais e acessa seu histórico. |
| **RF-005** | P0 | Simular eventos fictícios de comunicação e bateria. | O simulador gera cenários reproduzíveis de operação normal, bateria baixa e interrupção/retorno de comunicação. |
| **RF-006** | P0 | Receber eventos pela API REST. | Evento válido de dispositivo cadastrado é aceito, registrado e retorna resposta adequada. |
| **RF-007** | P0 | Validar os dados recebidos. | Percentual fora de 0–100, campos obrigatórios ausentes e dispositivo desconhecido são rejeitados de forma explícita. |
| **RF-008** | P0 | Registrar histórico de eventos por dispositivo. | Eventos aceitos permanecem disponíveis para consulta em ordem cronológica, com paginação quando aplicável. |
| **RF-009** | P0 | Avaliar a condição de bateria. | Medições são classificadas conforme o limite configurado e produzem o estado correspondente sem alterar registros históricos. |
| **RF-010** | P0 | Atualizar a situação de comunicação a partir de eventos válidos. | Nova comunicação válida é considerada na avaliação do estado do dispositivo, respeitando a ordenação definida em DP-004. |
| **RF-011** | P0 | Detectar falta de comunicação automaticamente. | Após ultrapassar o prazo estabelecido, um verificador interno identifica a situação sem depender de um novo evento. |
| **RF-012** | P0 | Gerar alerta quando a bateria atingir a condição crítica. | A ocorrência fica disponível na central de alertas e vinculada ao dispositivo. |
| **RF-013** | P0 | Gerar alerta de ausência de comunicação. | Um dispositivo que ultrapasse o prazo previsto é associado a uma ocorrência de comunicação. |
| **RF-014** | P0 | Impedir duplicação de alertas ativos equivalentes. | Eventos repetidos para a mesma condição não produzem alertas ativos duplicados. |
| **RF-015** | P0 | Permitir ao operador reconhecer alertas. | O reconhecimento é registrado; a condição técnica e o status de resolução permanecem independentes. |
| **RF-016** | P0 | Atualizar a resolução de alertas após normalização. | Quando a condição deixa de existir, o sistema aplica a regra de resolução e preserva o histórico. |
| **RF-017** | P0 | Consultar alertas ativos, reconhecidos e resolvidos. | A central apresenta situação, tipo, dispositivo e datas relevantes; filtros funcionam conforme a especificação. |
| **RF-018** | P0 | Exibir indicadores operacionais no dashboard. | O painel mostra totais de dispositivos, situações de comunicação e quantidade de alertas de forma consistente com a API. |
| **RF-019** | P1 | Atualizar informações exibidas sem recarregar a página inteira. | Dashboard e alertas refletem novas informações por atualização periódica controlada ou ação explícita de atualização. |
| **RF-020** | P0 | Informar falhas operacionais de forma compreensível. | Erros de validação, recursos não encontrados e indisponibilidade da API são sinalizados sem apresentar sucesso indevido. |

### Observações dos requisitos funcionais

1. **Sem medição inicial:** a interface deve distinguir a ausência de dados de uma medição real. O estado exato de comunicação inicial será definido em DP-004.
2. **Eventos duplicados e fora de ordem:** a estratégia de identificação e tratamento será especificada em DP-004 antes do contrato da API.
3. **Reconhecimento não é resolução:** a confirmação de leitura do operador não implica normalização de bateria ou comunicação.
4. **Atualização periódica:** o MVP pode utilizar consultas HTTP em intervalos; WebSockets não são obrigatórios.

## 4. Requisitos não funcionais

| ID | Categoria | Requisito | Critério de aceitação |
| --- | --- | --- | --- |
| **RNF-001** | Privacidade | Utilizar exclusivamente equipamentos e dados fictícios. | Nenhuma tela, seed ou documento contém dados operacionais reais de terceiros. |
| **RNF-002** | Segurança | Não versionar senhas, tokens ou credenciais. | Segredos ficam em variáveis de ambiente; repositório tem regras de exclusão adequadas. |
| **RNF-003** | Integridade | Preservar consistência entre dispositivos, eventos e alertas. | Referências inexistentes são rejeitadas e operações críticas evitam registros incoerentes. |
| **RNF-004** | Desempenho | Manter respostas adequadas para uma demonstração local. | Em ambiente local documentado, com até 100 dispositivos e 10 mil eventos simulados, listagens paginadas e indicadores respondem em até 2 segundos sob uma requisição por vez; validar em DP-012. |
| **RNF-005** | Usabilidade | Empregar linguagem simples e estados visuais claros. | O operador identifica situações, erros, carregamento e ausência de dados sem consultar documentação técnica. |
| **RNF-006** | Responsividade | Disponibilizar interface para desktop e celular. | Páginas principais mantêm conteúdo e ações acessíveis em viewport a partir de 360 px, sem rolagem horizontal indevida. |
| **RNF-007** | Acessibilidade | Oferecer operação básica por teclado e identificação textual de alertas. | Navegação principal e ação de reconhecer alerta funcionam por teclado; cor não é a única indicação de situação. |
| **RNF-008** | Testabilidade | Automatizar a verificação das principais regras e integrações. | Testes cobrem limiares de bateria, timeout, deduplicação, validação de eventos, reconhecimento e normalização. |
| **RNF-009** | Reprodutibilidade | Permitir instalar e executar o projeto a partir do repositório. | README inclui requisitos, preparação do banco, variáveis de exemplo, execução e dados fictícios para demonstração. |
| **RNF-010** | Interoperabilidade | Utilizar API HTTP/REST com JSON e respostas padronizadas. | Endpoints retornam códigos HTTP coerentes, payloads documentados e erros com estrutura consistente. |
| **RNF-011** | Rastreabilidade | Manter decisões técnicas, contratos e mudanças no GitHub. | Documentos, alterações, testes e funcionalidades são relacionados a cards e Pull Requests. |
| **RNF-012** | Publicação | Avaliar riscos antes de disponibilizar uma demonstração pública. | Uma eventual demo não expõe credenciais, dados reais ou endpoints de alteração sem proteção contra abuso; caso não seja seguro, a execução permanece local. |

## 5. Rastreabilidade inicial

| Capacidade de negócio | Casos de uso | Requisitos |
| --- | --- | --- |
| Cadastro e listagem | UC-001, UC-002 | RF-001 a RF-004 |
| Geração e recebimento de eventos | UC-003 | RF-005 a RF-010 |
| Detecção de ausência de comunicação | UC-004 | RF-010, RF-011, RF-013 |
| Monitoramento e indicadores | UC-005 | RF-002, RF-018, RF-019 |
| Histórico por dispositivo | UC-006 | RF-004, RF-008 |
| Reconhecimento de alerta | UC-007 | RF-015, RF-017 |
| Normalização de alerta | UC-008 | RF-009, RF-010, RF-014, RF-016 |

A matriz completa de rastreabilidade com regras de negócio, telas e casos de teste poderá ser complementada em DP-012 e mantida conforme a implementação evoluir.

## 6. Cenários para validação

### CEN-01 — Cadastro válido

**Dado que** o identificador ainda não existe,  
**quando** o operador cadastra um dispositivo com informações válidas,  
**então** ele passa a aparecer na listagem e pode receber eventos.

### CEN-02 — Identificador duplicado

**Dado que** o código já está cadastrado,  
**quando** outro dispositivo tenta usar o mesmo código,  
**então** o sistema rejeita o cadastro e preserva o registro original.

### CEN-03 — Alerta de bateria baixa

**Dado que** o dispositivo possui dados válidos,  
**quando** recebe uma medição dentro da faixa crítica definida,  
**então** o sistema registra a ocorrência e permite consultá-la.

### CEN-04 — Reconhecimento sem normalização

**Dado que** existe alerta ativo de bateria baixa,  
**quando** o operador confirma ciência,  
**então** o alerta fica reconhecido sem ser tratado como resolvido.

### CEN-05 — Falta de comunicação

**Dado que** um dispositivo tem última comunicação conhecida,  
**quando** o prazo configurado é ultrapassado sem novos eventos,  
**então** o verificador interno identifica a condição e atualiza estado e alerta.

### CEN-06 — Recuperação

**Dado que** existe uma condição de falha ativa,  
**quando** um evento válido posterior demonstra a normalização,  
**então** o sistema atualiza a situação conforme a regra e preserva o histórico da ocorrência.

## 7. Limites e exclusões

Não constituem requisitos do MVP: rastreamento GPS, monitoramento de pessoas, hardware real, autenticação multiusuário, notificações externas, inteligência artificial, aplicativo móvel nativo, WebSockets obrigatórios ou integração com plataformas proprietárias.

## 8. Pendências para aprovação posterior

- **DP-004:** confirmar limiar de bateria, duração de timeout, estado inicial, política de eventos duplicados/atrasados, transições e encerramento de alertas.
- **DP-005 a DP-007:** representar os fluxos, gateways e exceções nos diagramas BPMN.
- **DP-008 a DP-011:** derivar arquitetura, esquema de banco, endpoints e interfaces.
- **DP-012:** definir ambientes de teste e como medir os critérios de desempenho e qualidade.

## 9. Checklist de revisão

- [ ] Cada requisito funcional descreve um comportamento verificável.
- [ ] Cada RNF contém uma condição de qualidade que pode ser validada.
- [ ] Não há requisitos de funcionalidades excluídas do MVP.
- [ ] Os requisitos contemplam os oito casos de uso do Documento 02.
- [ ] Reconhecimento e resolução continuam conceitos distintos.
- [ ] Regras ainda provisórias estão identificadas e vinculadas ao DP-004.

**Próximo passo após aprovação:** DP-004 — Definir regras de negócio e estados de dispositivos e alertas.

---

*Documento de especificação inicial. Critérios e restrições poderão ser refinados mediante decisão registrada, antes do desenvolvimento.*
