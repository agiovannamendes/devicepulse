# DP-008 — Registros de Decisão Arquitetural (ADR)

**Versão:** 0.1  
**Estado de todos os ADRs:** Propostos, pendentes de aprovação do DP-008  
**Escopo:** DevicePulse — MVP com dispositivos e eventos exclusivamente fictícios

Uma *Architecture Decision Record* (ADR) registra o contexto da escolha, a decisão, suas consequências e opções rejeitadas. A aprovação deste documento indica que essas decisões passam a orientar arquitetura, API, banco, testes e implantação do MVP. Mudanças futuras devem ser registradas como novas decisões ou revisões explícitas.

## ADR-001 — Backend modular em um único processo (monólito modular)

**Contexto:** as funcionalidades de cadastro, ingestão de eventos, estados de dispositivos e alertas compartilham regras e a mesma base transacional. O MVP possui escopo limitado e não prevê escalabilidade de produção.

**Decisão proposta:** implementar uma aplicação Node.js + Express organizada em módulos por domínio/responsabilidade (rotas, validações, serviços/regras, repositórios e tarefas agendadas). Manter **um processo backend no MVP**. O verificador periódico de offline roda nesse processo, compartilhando os serviços de regras.

**Alternativas consideradas:** microserviços independentes; serviços separados para ingestão e alertas; função serverless para cada operação.

**Justificativa:** um processo facilita depuração, testes locais, transações, leitura do código e entrega integral, sem mensageria nem operações distribuídas.

**Consequências e limites:**
- Acoplamento operacional entre API e verificador; indisponibilidade do processo afeta os dois.
- Reinício do processo interrompe temporariamente a verificação; a retomada precisa reconciliar os dados.
- **Não iniciar o verificador duas vezes no mesmo processo.** Em futura hospedagem com múltiplas instâncias, será necessário lock/coordenação ou mover a rotina para um trabalhador dedicado.
- Separar módulos internamente **não** significa separar contêineres nem implantar serviços independentes.
- A implantação deve manter um processo persistente; ambientes que suspendem processos não garantem a verificação a cada 30 s.

**Rastreio:** DP-004 RN-009/011/017/018/020; DP-007 EX-22, EX-24 e EX-25.  
**Revisar se:** houver múltiplas instâncias, necessidade real de escala ou execução externa do verificador.

## ADR-002 — Persistência em PostgreSQL e consistência transacional

**Contexto:** eventos precisam manter histórico; alertas não podem duplicar para o mesmo dispositivo e tipo enquanto estiverem abertos; o processamento inclui comparações temporais e atualizações relacionadas.

**Decisão proposta:** usar um PostgreSQL único, com acesso restrito ao backend. Aplicar **chaves estrangeiras**, restrições de identidade/uniquidade, SQL parametrizado e transações no processamento de eventos, estados e alertas. A estratégia exata de migrações e tabelas será concluída no DP-009.

**Alternativas:** armazenamento apenas em memória; arquivos JSON; banco NoSQL sem relações explícitas; bancos separados para cada módulo.

**Consequências e limites:**
- A API e o verificador compartilham a mesma fonte de verdade.
- Eventos duplicados exigem chave de deduplicação persistida, preferencialmente com restrição de banco. O índice/chave exato para `eventId` será definido em DP-009 a partir de RN-002/RN-005.
- A regra **um alerta aberto por dispositivo e tipo** deve ser garantida no banco (ex.: índice único parcial ou equivalente), além da verificação no serviço.
- Não retornar sucesso se a operação transacional não for confirmada.
- Evento antigo pode ser registrado no histórico, mas **não** pode sobrescrever o estado derivado de evento mais recente.
- Recuperação operacional precisa ser idempotente, reavaliando com base em dados válidos.
- PostgreSQL adiciona dependência de configuração local; ela deve ser documentada com scripts ou contêiner local e valores de exemplo.

**Rastreio:** DP-003 RNF-003, RF-006 a RF-017; DP-004 RN-002/005/006/018/021; DP-007 EX-07 a EX-12 e EX-15.

## ADR-003 — HTTP/REST + JSON e atualização periódica no frontend

**Contexto:** o dashboard precisa apresentar status e alertas atualizados, mas não é necessário tempo real estrito para uma demonstração com aproximadamente até 100 dispositivos.

**Decisão proposta:** a SPA React realiza consultas REST ao backend, em **intervalos configuráveis** para os indicadores e alertas, além de requisições após ações do operador. O simulador envia eventos para a **mesma API REST**. Não incluir WebSockets na primeira versão.

**Alternativas:** WebSockets, Server-Sent Events (SSE), comunicação direta navegador–PostgreSQL.

**Consequências e limites:**
- Simplicidade de implementação, teste e documentação de contratos OpenAPI.
- Pode haver atraso entre mudança registrada no backend e atualização do painel (consistência eventual na apresentação).
- A interface deve indicar erro/carregamento e atualizar dados relevantes após reconhecer alertas.
- O intervalo de consulta da SPA **não é** o verificador offline de 30 s e **não é** o simulador de 60 s. Será ajustado no planejamento de UX e testes.
- Evitar solicitações sobrepostas e limpar timers quando componentes forem desmontados.
- Toda regra oficial é aplicada no backend; a SPA apenas apresenta os valores recebidos.
- O navegador nunca tem acesso direto ao banco de dados.

**Rastreio:** DP-003 RF-017/018/019/020; DP-004 limites de comunicação; DP-005/006 contratos de interação.  
**Revisar se:** a experiência exigir transmissão imediata comprovada por testes.

## ADR-004 — Simulador externo e verificador interno de comunicação

**Contexto:** o MVP não usa hardware. Deve ser possível reproduzir eventos normais, bateria baixa, falha de comunicação e retorno ao estado conectado.

**Decisão proposta:** criar um **simulador executado separadamente (Node.js CLI)** que faz POST JSON para o endpoint de ingestão do backend, normalmente a cada **60 segundos por dispositivo**. O verificador de offline permanece **interno ao backend**, realizando a checagem proposta a cada **30 segundos**.

**Alternativas:** simulador com acesso direto ao banco; eventos gravados manualmente na UI; rotina de offline dentro do navegador; broker de mensagens.

**Consequências e limites:**
- Reutiliza o mesmo caminho de validação de qualquer cliente de ingestão.
- O simulador deve manter a identidade do `eventId` nos reenvios do **mesmo evento**; cada ocorrência nova recebe novo identificador.
- É possível pausar os eventos de um dispositivo para demonstrar `OFFLINE` após mais de 300 segundos desde a última comunicação válida; o momento exato de detecção depende do próximo ciclo do verificador.
- Eventos atrasados aceitos no histórico não alteram o estado atual.
- Não prometer entrega garantida, fila persistente nem recuperação de eventos que o simulador nunca reenviar.
- O verificador inicia uma vez no processo Node; após reinício, recalcula a partir do histórico/última comunicação válida.
- Os mecanismos de segurança da API continuam válidos mesmo em ambiente de demonstração.

**Rastreio:** DP-004 RN-005/006/007/009/010/011; DP-007 EX-22 a EX-26.

## ADR-005 — Demonstração local como padrão e exposição pública controlada

**Contexto:** o MVP não possui autenticação multiusuário. Uma API de escrita aberta na internet permitiria cadastros, simulações e reconhecimento indevidos.

**Decisão proposta:** desenvolvimento e demonstração inicial **locais**, com segredos em variáveis de ambiente fora do Git e dados exclusivamente fictícios. Qualquer hospedagem pública deverá passar por revisão de segurança; preferir apresentação somente leitura ou adicionar controles adequados para operações de escrita.

**Alternativas:** liberar livremente endpoints de escrita no ambiente público; implementar autenticação avançada no MVP.

**Consequências e limites:**
- O GitHub será público, mas credenciais e arquivos `.env` reais não serão versionados.
- O uso de HTTPS em produção não substitui autorização, limitação de taxa, validação de dados e configuração adequada de CORS.
- Uma futura demonstração pública será **opcional**, após revisão dos endpoints e custos de hospedagem.
- Não introduzir GPS, dados pessoais de terceiros ou integração com sistemas proprietários.

**Rastreio:** DP-003 RNF-001/002/012; DP-012 e DP-036.  
**Revisar se:** for decidido disponibilizar operações de escrita em uma demonstração aberta.

## Situação e próximos passos

Todos os ADRs acima estão **propostos**. Os detalhes finais de esquema SQL, índices e migrações serão acordados no DP-009; endpoints e esquemas de erro, no DP-010; estrutura interna dos serviços e sequência de processamento, no trabalho posterior de arquitetura/componentes e implementação.

**Aprovação pendente:** confirmar se a separação de responsabilidades, a persistência, a estratégia de atualização do painel e os limites de hospedagem atendem ao DevicePulse.
