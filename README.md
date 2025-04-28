# Script de Configuração Docker & NFS

Este projeto contém um script de automação para configurar servidores Docker e NFS, permitindo que você configure um **Manager** ou **Worker** para um cluster Docker Swarm, instale o Docker, configure o NFS, e crie serviços Docker como MySQL e servidores web com Nginx.

## Funcionalidades

O script oferece um menu interativo com várias opções de configuração, incluindo:

### Para Manager:
- **Atualizar sistema**
- **Instalar NFS Server**
- **Configurar NFS (Network File System)**
- **Instalar Docker e Docker Compose**
- **Criar container MySQL**
- **Inserir dados no banco MySQL**
- **Iniciar Docker Swarm**
- **Criar serviço web no cluster Docker Swarm**
- **Criar proxy reverso com Nginx**

### Para Worker:
- **Atualizar sistema**
- **Instalar nfs-common**
- **Montar NFS**
- **Instalar Docker e Docker Compose**
- **Entrar no cluster Docker Swarm como Worker**

## Pré-requisitos

Antes de rodar o script, você precisa ter:

- **Sistema operacional**: Debian/Ubuntu (pode ser adaptado para outras distros)
- **Permissões de root** para instalar pacotes e configurar o sistema
- **Docker** instalado (caso não esteja, o script cuida disso)
- **Acesso à rede** para acessar outros servidores (se configurando um cluster Docker Swarm)

## Como usar

1. **Clone o repositório** no seu servidor:
   
   ```bash
   git clone https://github.com/seu-usuario/seu-repositorio.git
   cd seu-repositorio
