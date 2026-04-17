# Event-Driven Billing Engine 💳

![Node.js](https://img.shields.io/badge/Node.js-20+-339933?style=for-the-badge&logo=nodedotjs)
![NestJS](https://img.shields.io/badge/NestJS-E0234E?style=for-the-badge&logo=nestjs)
![AWS SQS](https://img.shields.io/badge/Messaging-AWS_SQS-FF9900?style=for-the-badge&logo=amazonsqs)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-4169E1?style=for-the-badge&logo=postgresql)
![Redis](https://img.shields.io/badge/Redis-7-DC382D?style=for-the-badge&logo=redis)
![Kubernetes](https://img.shields.io/badge/Kubernetes-AWS_EKS-blue?style=for-the-badge&logo=kubernetes)
![Terraform](https://img.shields.io/badge/IaC-Terraform-purple?style=for-the-badge&logo=terraform)
![Stripe](https://img.shields.io/badge/Payments-Stripe_API-6772E5?style=for-the-badge&logo=stripe)
![GitHub Actions](https://img.shields.io/badge/CI/CD-GitHub_Actions-2088FF?style=for-the-badge&logo=githubactions)

Ecossistema de microserviços de alta escalabilidade para processamento de faturamento assíncrono. O projeto utiliza **Stripe API** para transações reais, **AWS SQS** para mensageria resiliente e **Redis** para garantir que cada cobrança seja processada exatamente uma vez (**Idempotência**).

## 🚀 Objetivo
O foco principal é resolver o desafio da **consistência em sistemas distribuídos**. O motor de cobrança garante que, mesmo sob falhas de rede ou instabilidade do provedor de pagamento, o estado final do faturamento seja reconciliado sem duplicidade, utilizando **Correlation IDs** e arquitetura orientada a eventos.

## 🛠️ Stack Tecnológica
* **Linguagens:** TypeScript (Node.js 20+)
* **Frameworks:** NestJS (API Gateway) & Node.js Puro (Worker Consumer)
* **Mensageria:** AWS SQS
* **Banco de Dados:** PostgreSQL (Persistência Transacional)
* **Cache & Idempotência:** Redis
* **Pagamentos:** Stripe SDK (Integration em Test Mode)
* **Infraestrutura:** Kubernetes (AWS EKS) & Terraform (IaC)
* **CI/CD:** GitHub Actions (Pipelines de Testes, Build e Deploy)
* **Testes:** Jest
* **Containerização:** Docker & AWS ECR

---

## 🗺️ Roadmap de Desenvolvimento: Billing Engine

### ✅ 1. Infraestrutura como Código
* [x] **Bootstrap:** S3 para Remote State + Usuário IAM com chaves.
* [x] **Mensageria:** Módulo SQS (Standard + DLQ) configurado em *us-east-2*.
* [x] **Database & Cache:** RDS Postgres (v15) + ElastiCache Redis (v7).
* [x] **EKS:** Cluster Kubernetes v1.29 com Managed Node Groups (SPOT + AL2).

### 🚀 2. API Gateway & Mensageria
* [x] **Project Setup:** Scaffold do NestJS com ConfigService e validação rigorosa de `.env`.
* [x] **Stripe Module:** Integração completa com SDK do Stripe para criação de `PaymentIntent`.
* [x] **SQS Producer:** Implementação do serviço de despacho de mensagens para a fila de faturamento em Ohio.
* [x] **Observabilidade:** Middleware para gerar e injetar **Correlation ID (X-Correlation-ID)** globalmente.
* [x] **Webhook Security:** Handler para eventos do Stripe com validação de assinatura (HMAC) para confirmação de pagamento.
* [x] **Unit Tests:** Cobertura 100% mockada dos serviços de Billing e Stripe.

### 🛡️ 3. Worker Consumer
* [x] **SQS Consumer:** Implementação do listener assíncrono para processar a fila.
* [x] **Idempotência:** Estratégia de "Check-then-Act" usando Redis para evitar cobrança duplicada.
* [x] **Database Layer:** Persistência dos estados da transação (Pending, Succeeded, Failed).
* [x] **Retry Policy:** Configuração de visibilidade da fila e redrive para DLQ em caso de erro crítico.

### ☸️ 4. Orquestração Kubernetes
* [x] **Multi-stage Dockerfiles:** Criação de builds otimizados para API (NestJS) e Worker (Node Puro), garantindo imagens leves e seguras para produção.
* [x] **K8s Objects (API):** Escrita dos arquivos `deployment.yaml`, `service.yaml` (LoadBalancer) e `hpa.yaml` para o gateway.
* [x] **Worker Deployment:** Configuração de Deployment específico para o Worker (sem Service), com foco exclusivo em consumo assíncrono.
* [x] **Graceful Shutdown & Lifecycle:** Implementação de sinais de sistema (`SIGTERM`) e `terminationGracePeriod` para garantir que nenhuma cobrança seja interrompida durante deploys ou escalas.
* [x] **ConfigMaps & Secrets:** Externalização de todas as variáveis de ambiente e integração segura com Secrets do Kubernetes.
* [x] **Liveness & Readiness:** Implementação de probes (NestJS e Worker) para garantir a auto-recuperação de Pods travados e tráfego apenas em instâncias prontas.
* [x] **HPA (API):** Auto-scaling baseado em CPU (60%) e Memória (80%), com mínimo de 1 e máximo de 2 réplicas.
* [x] **HPA (Worker):** Auto-scaling baseado em CPU (70%), com mínimo de 1 e máximo de 2 réplicas.

### ⚙️ 5. Automação & CI/CD (GitOps & QA)
* [x] **CI Pipeline:** Workflow robusto no GitHub Actions com detecção inteligente de alterações (`paths-filter`) e execução de testes unitários (Jest) como gate de qualidade.
* [x] **Docker Strategy:** Pipeline de build multi-stage para API (NestJS) e Worker (Node.js), com armazenamento seguro no **Amazon ECR**.
* [x] **Auto-Discovery & IaC Integration:** Implementação de estágio de descoberta dinâmica via AWS CLI, capturando endpoints de RDS, ElastiCache e SQS para evitar *hardcoding*.
* [x] **CD Pipeline (Manifest-driven):** Deploy automatizado no EKS utilizando `envsubst` para injeção dinâmica de variáveis em manifestos nativos do Kubernetes.
* [x] **Secret Management:** Estratégia de sincronização de segredos entre GitHub Secrets e K8s Secrets, resolvendo o "Dilema do Webhook" do Stripe via re-feeds automatizados e `rollout restart`.

---

## 📋 Pré-requisitos

Antes de começar, você precisará ter instalado em sua máquina:

* **AWS CLI v2:** Autenticado e configurado via `aws configure`.
* **Terraform (v1.5+):** Motor de Infraestrutura como Código (IaC).
* **jq:** Processador de JSON via terminal (obrigatório para o `bootstrap.sh`).
* **Node.js 20+ & npm:** Runtime e gerenciador de pacotes para o NestJS e Worker.
* **Docker:** Para build de imagens.
* **kubectl:** CLI para administração do cluster Kubernetes.

---

## 🛠️ Guia de Instalação e Infraestrutura

### 0. Autenticação e Configuração AWS (Obrigatório)
Antes de rodar qualquer script, você precisa conectar seu terminal à sua conta AWS através de um usuário IAM com permissões administrativas.

**Caso não possua um usuário criado:**
1. Acesse o Console AWS com sua conta Root.
2. Vá em **IAM** -> **Users** -> **Create user**.
3. Nome: `admin-victor` | Selecione **Attach policies directly**.
4. Busque por **AdministratorAccess**, marque a política e finalize a criação.

**Gerando as Chaves de Acesso:**
1. No console IAM, clique no seu usuário (`admin-victor`) -> Aba **Security Credentials**.
2. Vá em **Access keys** -> **Create access key** -> Selecione **CLI**.
3. No seu terminal, rode:
   ```bash
   aws configure
   ```
4. Preencha conforme solicitado:
   * **AWS Access Key ID:** `Sua Chave Aqui`
   * **AWS Secret Access Key:** `Sua Secret Aqui`
   * **Default region name:** `us-east-2`
   * **Default output format:** `json`

5. Teste a conexão:
   ```bash
   aws sts get-caller-identity
   ```
   *(Se retornar o ARN do seu usuário, a autenticação está ok.)*

---

### 1. Bootstrap da Infraestrutura
```bash
chmod +x bootstrap.sh
./bootstrap.sh
```
> **⚠️ Importante:** O script imprimirá o nome do Bucket gerado (ex: `stbilling-enginetf123abc`). Copie esse nome e atualize o campo `bucket` no arquivo `terraform/main.tf` antes de prosseguir.

### 2. Configuração de Credenciais do Banco
```bash
export TF_VAR_db_username="admin_victor"
export TF_VAR_db_password="SuaSenhaSegura123"
```

### 3. Deploy da Infraestrutura (IaC)
```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```

### 4. Configuração do Contexto Kubernetes
```bash
aws eks update-kubeconfig --region us-east-2 --name billing-engine-v2-cluster
```

### 5. Configuração do Ambiente Kubernetes

Antes de executar o script, obtenha os seguintes segredos:

**STRIPE_SECRET_KEY:**
Acesse o [Dashboard do Stripe](https://dashboard.stripe.com/test/apikeys) e copie sua chave secreta de teste (`sk_test_...`). Essa chave já está disponível e não depende do deploy.

**STRIPE_WEBHOOK_SECRET:**
Esse valor tem uma dependência com o deploy — você só terá o `EXTERNAL-IP` do LoadBalancer depois que a aplicação subir no EKS. Por isso, o fluxo correto é:

1. **Primeira execução do script:** Deixe o `STRIPE_WEBHOOK_SECRET` em branco por enquanto (só pressione Enter). O cluster já ficará funcional para processar pagamentos.
2. **Após o deploy**, pegue o `EXTERNAL-IP` através do comando `kubectl get svc` e cadastre o webhook no Stripe:
   - Acesse [Dashboard do Stripe → Webhooks](https://dashboard.stripe.com/test/webhooks)
   - Clique em **Add endpoint**
   - URL: `http://<EXTERNAL-IP>/billing/webhook`
   - Evento: `payment_intent.succeeded`
   - Copie o **Signing Secret** gerado (`whsec_...`)
3. **Reexecute o script** para atualizar o Secret no cluster com o valor correto:
   ```bash
   ./setup-k8s-env.sh
   ```

Com isso em mente, primeiro faça a configuração de Acesso ao Cluster (RBAC/EKS Access)
```bash
USER_ARN=$(aws sts get-caller-identity --query Arn --output text)

aws eks create-access-entry --cluster-name billing-engine-v2-cluster \
    --principal-arn $USER_ARN --type STANDARD

aws eks associate-access-policy --cluster-name billing-engine-v2-cluster \
    --principal-arn $USER_ARN \
    --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
    --access-scope type=cluster
```

E depois, execute o script pela primeira vez:

```bash
chmod +x setup-k8s-env.sh
./setup-k8s-env.sh
```

> **🔑 O script solicitará no terminal:** `DB_PASSWORD`, `STRIPE_SECRET_KEY` e `STRIPE_WEBHOOK_SECRET`.

---

## ☸️ Orquestração Kubernetes

### 1. Autenticação no Amazon ECR
As URLs dos repositórios já são geradas pelo Terraform. Para autenticar o Docker:
```bash
# O script setup-k8s-env.sh já exporta as variáveis necessárias
source ./setup-k8s-env.sh

aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin $(echo $ECR_API_URL | cut -d'/' -f1)
```

### 2. Build e Push para o ECR
```bash
# Build e Push da API
docker build -t billing-api:v1 ./api-gateway
docker tag billing-api:v1 $ECR_API_URL:v1
docker push $ECR_API_URL:v1

# Build e Push do Worker
docker build -t billing-worker:v1 ./billing-worker
docker tag billing-worker:v1 $ECR_WORKER_URL:v1
docker push $ECR_WORKER_URL:v1
```

### 3. Deploy via Manifestos
```bash
export DOCKER_IMAGE_API="$ECR_API_URL:v1"
export DOCKER_IMAGE_WORKER="$ECR_WORKER_URL:v1"

# Aplicar Workloads
envsubst < k8s/api/deployment.yaml | kubectl apply -f -
kubectl apply -f k8s/api/svc.yaml
kubectl apply -f k8s/api/hpa.yaml

envsubst < k8s/worker/deployment.yaml | kubectl apply -f -
kubectl apply -f k8s/worker/hpa.yaml
```

### 4. Metrics Server (HPA)
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

---

## 🧪 Validando o Deploy no EKS

### 1. Obtendo o Endpoint da API

Após o deploy, aguarde o LoadBalancer provisionar o IP público:

```bash
kubectl get svc billing-api-service
```

Copie o valor da coluna `EXTERNAL-IP` — esse é o seu endpoint público. Se ainda aparecer `<pending>`, aguarde alguns minutos e rode o comando novamente.

### 2. Finalizando a Configuração do Webhook (STRIPE_WEBHOOK_SECRET)

Com o `EXTERNAL-IP` em mãos, volte ao [Dashboard do Stripe → Webhooks](https://dashboard.stripe.com/test/webhooks):

1. Clique em **Add endpoint**
2. URL: `http://<EXTERNAL-IP>/billing/webhook`
3. Evento: selecione `payment_intent.succeeded`
4. Copie o **Signing Secret** gerado (`whsec_...`)

Agora reexecute o script para atualizar o Secret no cluster e reinicie os pods para que peguem o novo valor:

```bash
./setup-k8s-env.sh

kubectl rollout restart deployment billing-api

kubectl rollout restart deployment billing-worker
```

### 3. Disparando um Checkout
```bash
curl -X POST http://<EXTERNAL-IP>/billing/checkout \
     -H "Content-Type: application/json" \
     -d '{"amount": 100}'
```
**Resposta esperada:**
```json
{ "status": "transaction_initiated", "transactionId": "...", "correlationId": "..." }
```

### 4. Consultando o Status da Transação
```bash
curl http://<EXTERNAL-IP>/billing/status/<transactionId>
```
**Resposta esperada:**
```json
{ "transactionId": "...", "correlationId": "...", "status": "SUCCEEDED", "updatedAt": "2026-04-13T12:01:04.609Z" }
```

### 5. Testando a Idempotência

Copie o `correlationId` e `transactionId` de um processamento anterior e reenvie a mensagem manualmente para simular uma duplicidade.

Primeiro, recupere a URL da fila direto do ConfigMap do cluster:

```bash
kubectl get configmap billing-config -o jsonpath='{.data.AWS_SQS_QUEUE_URL}'
```

Agora envie a mensagem duplicada:

```bash
aws sqs send-message \
  --queue-url <AWS_SQS_QUEUE_URL> \
  --message-body '{
    "transactionId": "<id-aqui>",
    "correlationId": "<correlation-id-aqui>",
    "amount": 100
  }'
```

Verifique os logs do Worker:
```bash
kubectl logs -l app=billing-worker --tail=50
```

**Resultado esperado nos logs do Worker:**
```
[<correlationId>] Processando cobrança: <transactionId>
[<correlationId>] Transação finalizada com sucesso.
[<correlationId>] Processando cobrança: <transactionId>
[<correlationId>] Mensagem duplicada ignorada.
```

A primeira mensagem é processada normalmente. A segunda, com os mesmos IDs, é interceptada pelo Redis e descartada sem tocar no Stripe ou no banco — o campo `updatedAt` da transação não deve ser alterado.

### 6. Monitoramento de Escala
```bash
kubectl get hpa
```

---

### 🚀 Guia de Execução e CI/CD

O deploy deste ecossistema é totalmente automatizado, mas segue um fluxo lógico para garantir que a infraestrutura e os segredos de negócio estejam sincronizados.

#### 1. Bootstrap da Infraestrutura (Máquina Local)
Antes do primeiro push, você precisa preparar o terreno na AWS para que o GitHub Actions tenha onde guardar o estado do Terraform e permissão para criar recursos:

1. Execute o script de bootstrap:
   ```bash
   chmod +x bootstrap.sh
   ./bootstrap.sh
   ```
2. O script criará um **Bucket S3** (para o Terraform State) e um **Usuário IAM** com permissões administrativas.
3. **Importante:** Copie o nome do bucket gerado e cole no arquivo `terraform/main.tf`, dentro do bloco `backend "s3"`.

#### 2. Configuração de Secrets no GitHub
Acesse seu repositório em **Settings > Secrets and Variables > Actions** e cadastre as seguintes variáveis:

| Variável | Origem | Descrição |
| :--- | :--- | :--- |
| `AWS_ACCESS_KEY_ID` | `bootstrap.sh` | ID da chave de acesso do usuário IAM criado. |
| `AWS_SECRET_ACCESS_KEY` | `bootstrap.sh` | Chave secreta do usuário IAM criado. |
| `AWS_REGION` | `bootstrap.sh` | Região definida no bootstrap (Padrão: `us-east-2`). |
| `DB_USERNAME` | **Você define** | Usuário administrativo do RDS Postgres. |
| `DB_PASSWORD` | **Você define** | Senha forte para o banco de dados. |
| `STRIPE_SECRET_KEY` | [Stripe Dashboard](https://dashboard.stripe.com/test/apikeys) | Sua Secret Key de teste (`sk_test_...`). |
| `STRIPE_WEBHOOK_SECRET` | [Stripe Webhooks](https://dashboard.stripe.com/test/webhooks) | **Deixe vazio no 1º deploy.** (Veja "O Dilema do Webhook"). |

#### 3. O Fluxo de Deploy Automatizado
Após configurar os Secrets, o fluxo segue esta ordem:

* **Git Push:** O pipeline detecta alterações e inicia o Job de Terraform.
* **Provisionamento:** O RDS, ElastiCache, SQS e o **Cluster EKS (v1.33)** são criados.
* **Auto-Discovery:** O pipeline consulta a AWS para descobrir os novos Endpoints e gera o `ConfigMap` dinamicamente.
* **QA & Build:** Testes unitários do NestJS são executados e imagens Docker enviadas ao ECR.
* **K8s Deploy:** O pipeline aplica os manifestos no cluster via `envsubst`.

---

### 🛡️ O Dilema do Webhook (Resolvido com Artefatos)

Em sistemas de faturamento, o Stripe exige uma URL de destino, mas essa URL (LoadBalancer) só nasce após o deploy. Como o GitHub Actions mascara URLs de Cloud nos logs (`***`), usamos **Artefatos de Pipeline** para obter o endereço real.

**Para fechar o ciclo:**

1.  **Primeiro Deploy:** Execute o pipeline com `STRIPE_WEBHOOK_SECRET` vazio.
2.  **Captura da URL:** * No GitHub, clique na aba **Actions** e selecione a última execução.
    * No topo ou final da página, procure pela seção **Artifacts**.
    * Baixe o arquivo `link-da-api-stripe` (ou nome similar definido no workflow).
    * Abra o arquivo `.txt` contido no zip para copiar o endereço do LoadBalancer sem máscaras.
3.  **Configuração:** Cadastre a URL `http://<DNS_DO_LB>/billing/webhook` no Stripe.
4.  **Ativação:** Pegue o **Signing Secret** (`whsec_...`), salve no GitHub Secrets e rode o pipeline novamente para ativar a segurança HMAC.

---

### 🧪 Validando a API (EKS)

Para testar o ecossistema em produção, utilize o mesmo procedimento descrito na documentação de desenvolvimento (scripts de teste ou Insomnia/Postman), substituindo o `localhost` pelo **Hostname do LoadBalancer** obtido via artefato.

**Exemplo via cURL:**
```bash
# O EXTERNAL_ID é o hostname extraído do arquivo de artefato
curl http://<EXTERNAL_ID>/health
```

---

### ⚙️ Arquitetura do Pipeline CI/CD

O arquivo `.github/workflows/main.yml` implementa uma esteira de **GitOps**:
* **Versão Moderna:** Cluster rodando Kubernetes **1.33** com **Amazon Linux 2023 (AL2023)**.
* **Idempotência:** O Terraform garante a integridade da infraestrutura.
* **Injeção Dinâmica:** Uso de `envsubst` para preencher `k8s/secrets.yaml` e `k8s/configmap.yaml` em runtime.
* **Zero Downtime:** Deploy com estratégias de *Rolling Update* para processamento contínuo de mensagens.
