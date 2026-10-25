# DevicePulse — Documento 01: Visão e Escopo do MVP

**Versão:** 1.0  
**Situação:** Aprovado — escopo inicial  
**Projeto:** DevicePulse  
**Tipo:** Aplicação web Full Stack com dados simulados

## 1. Contexto

O DevicePulse é um projeto independente de portfólio que simula uma central de monitoramento de dispositivos eletrônicos conectados. A aplicação reunirá informações de conectividade, bateria, eventos e alertas em uma interface web.

Os equipamentos e eventos serão fictícios. Não haverá integração com dispositivos comerciais reais ou sistemas proprietários de terceiros.

## 2. Problema

Acompanhar o estado de diversos dispositivos sem uma visão centralizada dificulta identificar problemas, consultar ocorrências anteriores e entender quais situações já foram verificadas por um operador.

Neste projeto, o cenário de operação é **hipotético**: uma equipe precisa acompanhar dispositivos que enviam periodicamente informações ao sistema e reagir quando deixam de comunicar ou apresentam bateria baixa.

## 3. Objetivo

### Objetivo geral

Desenvolver uma aplicação web que receba eventos simulados de dispositivos, registre seu histórico, calcule situações operacionais e apresente alertas ao operador.

### Objetivos específicos

- Centralizar o cadastro e a visualização dos dispositivos.
- Armazenar eventos de comunicação e nível de bateria.
- Identificar ausência de comunicação e condições de bateria baixa.
- Permitir acompanhar e reconhecer alertas.
- Consultar o histórico por dispositivo.
- Oferecer um painel com indicadores operacionais.

## 4. Usuários e participantes

| Participante | Responsabilidade |
| --- | --- |
| Operador de monitoramento | Consultar o painel, buscar dispositivos e reconhecer alertas. |
| Simulador | Produzir eventos fictícios para testar diferentes condições operacionais. |
| Sistema DevicePulse | Validar eventos, atualizar estados, registrar histórico e gerenciar alertas. |

O MVP terá apenas o papel conceitual de operador, sem autenticação ou gestão de múltiplos usuários. O impacto dessa decisão em uma eventual demonstração pública será avaliado antes do deploy.

## 5. Escopo do MVP

| ID | Capacidade | Descrição |
| --- | --- | --- |
| CAP-01 | Cadastro de dispositivos | Registrar dispositivos com identificador único e informações básicas. |
| CAP-02 | Consulta e filtros | Listar e localizar dispositivos por código, nome e situação. |
| CAP-03 | Simulação de eventos | Produzir medições fictícias de bateria e comunicação. |
| CAP-04 | Recebimento de eventos | Validar e armazenar eventos enviados ao backend. |
| CAP-05 | Monitoramento | Determinar o estado de comunicação de cada dispositivo. |
| CAP-06 | Alertas | Identificar bateria baixa e ausência de comunicação. |
| CAP-07 | Acompanhamento de alertas | Consultar, reconhecer e acompanhar a resolução de ocorrências. |
| CAP-08 | Histórico | Exibir eventos e mudanças relevantes ao longo do tempo. |
| CAP-09 | Dashboard | Apresentar totais, situações operacionais e alertas recentes. |

Estas capacidades serão detalhadas e numeradas como requisitos funcionais no Documento 03 (DP-003).

## 6. Fora do escopo

Não fazem parte da primeira versão:

- Localização GPS ou rastreamento de pessoas.
- Dispositivos físicos e dados reais de telemetria.
- Integração com plataformas ou serviços proprietários de terceiros.
- Aplicativo móvel nativo.
- Inteligência artificial e previsões automatizadas.
- Múltiplos perfis e controle avançado de acesso.
- Mensageria distribuída ou infraestrutura de alta escala.
- Notificações externas por e-mail, SMS ou WhatsApp.

## 7. Regras preliminares

As seguintes regras são **hipóteses iniciais**, sujeitas à validação no card DP-004:

- Cada dispositivo terá um identificador único.
- O percentual de bateria recebido deverá estar entre 0 e 100.
- Um nível de bateria igual ou inferior a 20% será considerado baixo.
- Um dispositivo poderá ficar offline após ultrapassar um intervalo configurável sem comunicação. O tempo exato ainda será definido.
- A repetição da mesma condição não deverá abrir vários alertas ativos equivalentes.
- **Reconhecer** um alerta significa registrar que o operador tomou ciência dele; **resolver** depende da normalização da condição ou da regra formal de resolução.
- O histórico deverá ser preservado mesmo depois que um alerta for resolvido.

## 8. Cenários de uso

### Cenário A — Operação normal

1. O simulador produz um evento válido com bateria de 86%.
2. A API recebe e registra o evento.
3. O sistema atualiza os dados do dispositivo.
4. O operador consulta o equipamento no painel.

**Resultado esperado:** o dispositivo aparece com informações recentes e sem alerta de bateria baixa.

### Cenário B — Bateria baixa

1. O simulador envia uma medição indicando 12% de bateria.
2. O sistema valida e registra o evento.
3. A regra de bateria baixa é acionada.
4. Um alerta ativo é disponibilizado ao operador.
5. O operador reconhece a ocorrência.

**Resultado esperado:** o alerta fica reconhecido, mas não é automaticamente tratado como resolvido.

### Cenário C — Falta de comunicação

1. Um dispositivo deixa de enviar eventos.
2. O intervalo máximo permitido sem comunicação é ultrapassado.
3. O sistema classifica a comunicação como offline e registra um alerta.
4. Posteriormente, uma comunicação válida é recebida.

**Resultado esperado:** o status e o alerta são atualizados conforme regras definidas, sem apagar o histórico.

## 9. Proposta tecnológica

A escolha preliminar é desenvolver o sistema com:

- **Frontend:** React, Vite e JavaScript.
- **Backend:** Node.js, Express e JavaScript.
- **Banco de dados:** PostgreSQL.
- **Testes:** ferramentas de teste para regras, API e interface.
- **Versionamento:** Git e GitHub.

A arquitetura, a estrutura de pastas, os contratos e as bibliotecas específicas serão definidos nos documentos técnicos seguintes.

## 10. Critérios de sucesso do MVP

Consideraremos a primeira versão funcional quando for possível:

1. Cadastrar e consultar dispositivos fictícios.
2. Gerar e receber eventos simulados de forma reproduzível.
3. Visualizar mudanças de conectividade e bateria.
4. Gerar e acompanhar alertas sem duplicações indevidas.
5. Reconhecer alertas sem confundir essa ação com a resolução.
6. Consultar histórico e indicadores corretos no painel.
7. Executar os testes essenciais.
8. Reproduzir a aplicação seguindo as instruções do repositório.

## 11. Restrições e riscos

- Todo o conteúdo operacional será fictício.
- A primeira versão será dimensionada para uma demonstração de portfólio, não para operação crítica.
- Uma eventual publicação na internet exigirá avaliação de segurança e controle de abuso dos endpoints.
- Regras temporais, ordenação e deduplicação de eventos precisam ser definidas antes do desenvolvimento.
- O escopo deverá permanecer enxuto para permitir uma entrega completa e bem testada.

## 12. Decisões pendentes

| Questão | Onde será definida |
| --- | --- |
| Qual intervalo caracteriza a perda de comunicação? | DP-004 — Regras de negócio |
| Como tratar eventos duplicados ou fora de ordem? | DP-004 e DP-007 |
| Como organizar componentes e fluxo de dados? | DP-008 — Arquitetura |
| Quais tabelas e campos serão necessários? | DP-009 — DER |
| Quais endpoints estarão disponíveis? | DP-010 — Contrato REST |
| Qual a navegação e aparência das telas? | DP-011 — Wireframes |
| Como serão executados os testes? | DP-012 — Plano de testes |

---

**Próximo passo:** detalhar os usuários, a jornada e os casos de uso no DP-002. As regras ainda preliminares serão definidas em DP-004.

*Este projeto é independente e não representa produtos, sistemas ou dados internos de empresas de monitoramento.*
