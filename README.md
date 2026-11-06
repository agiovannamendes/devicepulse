
# DevicePulse

Sistema web Full Stack para monitoramento de dispositivos eletrônicos simulados, utilizando JavaScript, React, Node.js, Express e PostgreSQL.

Permite acompanhar conectividade e bateria, registrar eventos, identificar falhas, gerenciar alertas e consultar históricos em um painel integrado a uma API REST.

## Ambiente de desenvolvimento

O DevicePulse utiliza um monorepo JavaScript com npm Workspaces.

### Tecnologias previstas

- Frontend: React e Vite
- Backend: Node.js e Express
- Simulador: Node.js
- Banco de dados: PostgreSQL

### Estrutura do projeto

- `frontend/` — interface do usuário
- `backend/` — API REST e regras de negócio
- `simulator/` — geração de dados fictícios
- `docs/` — documentação técnica e de produto

### Requisitos

- Node.js
- npm
- Git

### Instalação inicial

Na raiz do projeto, execute:

```powershell
npm.cmd install
```

### Verificar os workspaces

```powershell
npm.cmd run check:workspaces
```

O comando deve identificar `frontend`, `backend` e `simulator`.

### Variáveis de ambiente

O arquivo `.env.example` contém exemplos de configuração.

As credenciais reais devem permanecer em arquivos `.env`, que não são versionados no Git.

### Estado atual

O monorepo está em preparação. As aplicações React, Express e o simulador serão implementados nos próximos cards.
