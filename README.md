# Trabalho Individual - Gerência de Configuração e Evolução de Software (2026-1)

Os conhecimentos de Gerência de Configuração e Evolução de Software (GCES) são fundamentais no ciclo de vida de um produto de software moderno. Este trabalho tem como objetivo exercitar os conceitos de automação, isolamento de ambiente, testes, segurança (DevSecOps) e deploy contínuo.

A aplicação base é o **mk.js**, um jogo de luta implementado com Backend em Node.js/Express e Frontend em HTML5 Canvas/JavaScript. O projeto original é considerado *deprecated* e possui dependências antigas; parte do desafio é modernizar o ambiente para que ele execute com versões estáveis atuais.

## Requisitos do Projeto

O trabalho está dividido em 10 etapas, cada uma valendo **1,0 ponto**. O foco é a implementação técnica aliada à correta documentação e histórico de commits.

### Critérios de Avaliação (10 Fases)

| Fase | Descrição Técnica | Nota por etapa |
|---|---|---|
| 1. **Containerização (DEV)** | Elaboração de `Dockerfile` para ambiente de desenvolvimento com suporte a hot-reload (mudanças no código refletidas imediatamente no container). | 0-10% |
| 2. **Docker Compose (DEV)** | Configuração de um `docker-compose.yml` que integre a aplicação e um banco de dados **Postgres**. Você deve implementar uma camada simples de persistência no código (ex: salvar histórico de lutas ou nomes de jogadores). | 10% - 20% |
| 3. **CI - Build & Lint** | Automação das etapas de Build e Lint (Front e Back) via GitHub Actions. O pipeline deve falhar se o lint encontrar erros. | 20% - 30% |
| 4. **CI - Testes Unitários** | Implementação de testes unitários funcionais. **Obrigatório:** Commits sequenciais demonstrando o teste quebrando no CI e, em seguida, passando após correção. | 30% - 40% |
| 5. **CI - Testes de Fuzzing** | Implementação de testes de Fuzzing para validar a resiliência das entradas do servidor (Back-end) contra dados inesperados. | 40% - 50% |
| 6. **Segurança - SAST & SCA** | Integração de ferramentas de análise estática de segurança (SAST) e verificação de vulnerabilidades em dependências (SCA - ex: Snyk ou npm audit). | 50% - 60% |
| 7. **Qualidade de Código** | Integração completa com o **SonarCloud** no pipeline de CI, garantindo métricas de qualidade e cobertura mínima. | 60% - 70% |
| 8. **Containerização (PROD)** | Elaboração de `Dockerfiles` otimizados para produção (multi-stage build, baseados em Alpine) e configuração do **Nginx** como servidor de arquivos estáticos. | 70% - 80% | 
| 9. **Infraestrutura (K8s & Terraform)** | Criação de manifestos de **Kubernetes (K8s)** para orquestração da aplicação. Opcionalmente, utilize **Terraform** para provisionar a infraestrutura necessária. | 80% - 90% |
| 10. **CD & Segurança de Rede** | Deploy Contínuo com publicação de imagens e configuração de **HTTPS via Cert Manager**. O Nginx deve redirecionar porta 80 para 443 e não expor outras portas para fora da rede de containers. | 90% - 100% |

## Orientações Gerais

*   **Repositório:** O trabalho deve ser desenvolvido em um repositório pessoal no GitHub.
*   **Commits:** Devem ser atômicos e espaçados no tempo. Commits realizados todos juntos na data de entrega serão penalizados.
*   **Modernização:** É responsabilidade do aluno atualizar o `package.json` e as dependências do servidor para garantir compatibilidade com as versões mais recentes do Node.js.
*   **Documentação:** O `README.md` final deve conter o passo a passo de como subir o ambiente de desenvolvimento e como visualizar o ambiente de produção.

## Como Executar o Projeto

### Ambiente de Desenvolvimento (Hot-Reload)

Para rodar o ambiente de desenvolvimento utilizando o Docker com suporte a hot-reload e banco de dados PostgreSQL integrado:

1. Certifique-se de que possui o [Docker e Docker Compose](https://docs.docker.com/compose/install/) instalados.
2. Na raiz do projeto, execute o comando:
   ```bash
   docker compose up --build
   ```
3. O servidor estará disponível em `http://localhost:55555`. Qualquer alteração no código do backend (`server/`) ou frontend (`game/`) irá recarregar automaticamente.

### Ambiente de Produção (Nginx e Node Alpine)

Para visualizar o projeto em um ambiente otimizado para produção, onde o frontend é servido via **Nginx** (porta 80) e o backend roda no Node usando Alpine Linux:

1. Na raiz do projeto, execute o docker-compose específico de produção:
   ```bash
   docker compose -f docker-compose.prod.yml up --build -d
   ```
2. O jogo em produção (Frontend via Nginx) estará disponível em `http://localhost`.
3. O backend em produção responderá em `http://localhost:55555`.

### Kubernetes (Minikube)

Para orquestrar a aplicação em um cluster Kubernetes local com [Minikube](https://minikube.sigs.k8s.io/docs/start/):

1. Inicie o Minikube e habilite o Ingress Controller:
   ```bash
   minikube start
   minikube addons enable ingress
   ```

2. Configure o Docker para usar o ambiente do Minikube e construa as imagens:
   ```bash
   eval $(minikube docker-env)
   docker build -t mkjs-frontend:latest ./game
   docker build -t mkjs-backend:latest ./server
   ```

3. Aplique os manifestos do Kubernetes:
   ```bash
   kubectl apply -f k8s/namespace.yaml
   kubectl apply -f k8s/postgres-secret.yaml
   kubectl apply -f k8s/postgres-pvc.yaml
   kubectl apply -f k8s/postgres-deployment.yaml
   kubectl apply -f k8s/postgres-service.yaml
   kubectl apply -f k8s/backend-deployment.yaml
   kubectl apply -f k8s/backend-service.yaml
   kubectl apply -f k8s/frontend-deployment.yaml
   kubectl apply -f k8s/frontend-service.yaml
   kubectl apply -f k8s/ingress.yaml
   ```

4. Adicione o hostname ao `/etc/hosts`:
   ```bash
   echo "$(minikube ip) mkjs.local" | sudo tee -a /etc/hosts
   ```

5. Acesse a aplicação em `http://mkjs.local`.

6. Para verificar o status dos pods:
   ```bash
   kubectl get pods -n mkjs
   ```

### Terraform (Opcional)

Para provisionar a infraestrutura via [Terraform](https://developer.hashicorp.com/terraform/install):

1. Certifique-se de que o Minikube está rodando e as imagens foram construídas (passos 1-2 acima).

2. Inicialize e aplique o Terraform:
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

3. Para destruir a infraestrutura:
   ```bash
   terraform destroy
   ```

### Deploy Contínuo (CD)

O pipeline de CD é acionado automaticamente em cada push na branch `main` e realiza:

1. **Build** das imagens Docker do frontend e backend.
2. **Publicação** no GitHub Container Registry (GHCR):
   - `ghcr.io/gabrielsarcan/mkjs-frontend:latest`
   - `ghcr.io/gabrielsarcan/mkjs-backend:latest`
3. **Tags** com SHA do commit para rastreabilidade.

O workflow está em `.github/workflows/cd.yml` e utiliza o `GITHUB_TOKEN` nativo para autenticação no GHCR.

### HTTPS via Cert-Manager

Para habilitar HTTPS com certificados TLS automáticos via Let's Encrypt:

1. Instale o cert-manager no cluster:
   ```bash
   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.2/cert-manager.yaml
   ```

2. Aplique o ClusterIssuer e o Certificate:
   ```bash
   kubectl apply -f k8s/cert-manager-issuer.yaml
   kubectl apply -f k8s/certificate.yaml
   ```

3. O Ingress já está configurado para:
   - Terminar TLS com o certificado emitido automaticamente.
   - **Redirecionar HTTP (porta 80) para HTTPS (porta 443)** automaticamente.

4. Aplique as NetworkPolicies para segurança de rede:
   ```bash
   kubectl apply -f k8s/network-policy.yaml
   ```

### Segurança de Rede

As `NetworkPolicies` garantem que:

- **Frontend**: aceita tráfego somente do Ingress Controller (nginx).
- **Backend**: aceita tráfego somente do Ingress Controller e só pode acessar o PostgreSQL.
- **PostgreSQL**: aceita tráfego **somente do backend**. Nenhuma porta exposta para fora da rede de containers.
- **Externamente**: apenas as portas 80 (redirect) e 443 (HTTPS) são acessíveis.

Boa sorte!
