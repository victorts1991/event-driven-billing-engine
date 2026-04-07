# Event-Driven Billing Engine 💳

![Status: Em Desenvolvimento](https://img.shields.io/badge/Status-Em_Desenvolvimento-yellow?style=for-the-badge&logo=github)
![Kubernetes](https://img.shields.io/badge/Kubernetes-Localstack-blue?style=for-the-badge&logo=kubernetes)
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
* **Infraestrutura:** Kubernetes (K8s) & Terraform (IaC)
* **CI/CD:** GitHub Actions (Pipelines de Testes, Build e Deploy)
* **Testes:** Jest & Supertest (Unitários e E2E)
* **Containerização:** Docker & Docker Compose

---

## 🗺️ Roadmap de Desenvolvimento: Billing Engine

### ✅ 1. Infraestrutura como Código (Terraform)
* [x] **Bootstrap:** S3 para Remote State + Usuário IAM com chaves.
* [x] **Mensageria:** Módulo SQS (Standard + DLQ) configurado em *us-east-2*.
* [x] **Database & Cache:** RDS Postgres (v15) + ElastiCache Redis (v7).
* [x] **EKS:** Cluster Kubernetes v1.29 com Managed Node Groups (SPOT + AL2).

### 🚀 2. API Gateway & Mensageria (NestJS)
* [x] **Project Setup:** Scaffold do NestJS com ConfigService e validação rigorosa de `.env`.
* [x] **Stripe Module:** Integração completa com SDK do Stripe para criação de `PaymentIntent`.
* [x] **SQS Producer:** Implementação do serviço de despacho de mensagens para a fila de faturamento em Ohio.
* [x] **Observabilidade:** Middleware para gerar e injetar **Correlation ID (X-Correlation-ID)** globalmente.
* [x] **Webhook Security:** Handler para eventos do Stripe com validação de assinatura (HMAC) para confirmação de pagamento.
* [x] **Unit Tests:** Cobertura 100% mockada dos serviços de Billing e Stripe.

### 🛡️ 3. Worker Consumer (Resiliência & Idempotência)
* [x] **SQS Consumer:** Implementação do listener assíncrono para processar a fila.
* [x] **Idempotência:** Estratégia de "Check-then-Act" usando Redis para evitar cobrança duplicada.
* [x] **Database Layer:** Persistência dos estados da transação (Pending, Succeeded, Failed).
* [x] **Retry Policy:** Configuração de visibilidade da fila e redrive para DLQ em caso de erro crítico.

### ☸️ 4. Orquestração Kubernetes (Manifestos & Alta Disponibilidade)

* [ ] **Multi-stage Dockerfiles:** Criação de builds otimizados para API (NestJS) e Worker (Node Puro), garantindo imagens leves e seguras para produção.
* [ ] **K8s Objects (API):** Escrita dos arquivos `deployment.yaml`, `service.yaml` (LoadBalancer) e `hpa.yaml` para o gateway.
* [ ] **Worker Deployment:** Configuração de Deployment específico para o Worker (sem Service), com foco exclusivo em consumo assíncrono.
* [ ] **Graceful Shutdown & Lifecycle:** Implementação de sinais de sistema (`SIGTERM`) e `terminationGracePeriod` para garantir que nenhuma cobrança seja interrompida durante deploys ou escalas.
* [ ] **ConfigMaps & Secrets:** Externalização de todas as variáveis de ambiente e integração segura com Secrets do Kubernetes.
* [ ] **Liveness & Readiness:** Implementação de probes (NestJS e Worker) para garantir a auto-recuperação de Pods travados e tráfego apenas em instâncias prontas.
* [ ] **Smarter Scaling (HPA):** Configuração de auto-scaling do Worker baseado no backlog da fila SQS (mensageria) em vez de apenas CPU/RAM.

### ⚙️ 5. Automação & CI/CD (The Grand Finale)
* [ ] **Dockerization:** Dockerfile multi-stage otimizado para produção.
* [ ] **CI Pipeline:** GitHub Actions para rodar testes e build da imagem.
* [ ] **CD Pipeline:** Deploy automatizado no EKS (Helm ou K8s Manifests).
* [ ] **Secret Management:** Injeção segura de credenciais via AWS Secrets Manager ou Terraform.

---

## 📋 Pré-requisitos

Antes de começar, você precisará ter instalado em sua máquina:

* **AWS CLI v2:** Autenticado e configurado via `aws configure`.
* **Terraform (v1.5+):** Motor de Infraestrutura como Código (IaC).
* **jq:** Processador de JSON via terminal (obrigatório para o `bootstrap.sh`).
* **Helm (v3+):** Gerenciador de pacotes para Kubernetes (EKS).
* **Node.js 20+ & npm:** Runtime e gerenciador de pacotes para o NestJS e Worker.
* **Docker & Docker Compose:** Para testes de integração locais e build de imagens.
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
O script de bootstrap cria o Bucket S3 para o State do Terraform de forma automática para evitar conflitos de estado.
```bash
# Permissão de execução
chmod +x bootstrap.sh

# Executar o script
./bootstrap.sh
```
> **⚠️ Importante:** O script imprimirá o nome do Bucket gerado (ex: `stbilling-enginetf123abc`). Copie esse nome e atualize o campo `bucket` no arquivo `terraform/main.tf` antes de prosseguir.

### 2. Configuração de Credenciais do Banco
O RDS exige credenciais que não devem estar no código. Exporte-as como variáveis de ambiente (o Terraform as lerá automaticamente via prefixo `TF_VAR_`):

```bash
export TF_VAR_db_username="admin_victor"
export TF_VAR_db_password="SuaSenhaSegura123"
```

### 3. Deploy da Infraestrutura (IaC)
Com o backend configurado e as credenciais exportadas, suba o ecossistema (SQS, Redis, RDS, EKS):

```bash
cd terraform

# Inicializa o provedor e o backend remoto no S3
terraform init

# Gera o plano de execução para conferência
terraform plan

# Provisiona a infraestrutura
terraform apply -auto-approve
```

### 4. Configuração do Contexto Kubernetes
Após o sucesso do Terraform, conecte seu `kubectl` ao cluster criado:

```bash
aws eks update-kubeconfig --region us-east-2 --name billing-engine-cluster
```

### 5. Configuração do Ambiente de Desenvolvimento (API Gateway)

Após subir a infraestrutura, precisamos conectar a API NestJS aos recursos reais.

#### Gerando o arquivo .env
```bash
chmod +x setup-env.sh
./setup-env.sh
```

#### 🔑 Configuração Manual de Segredos (Obrigatório)
Edite o arquivo `./api-gateway/.env` e preencha as variáveis abaixo. **Atenção:** o Webhook Secret local é diferente do Webhook Secret de produção.

1.  **DB_PASSWORD:** Senha definida na etapa de infraestrutura (`TF_VAR_db_password`).
2.  **STRIPE_SECRET_KEY:** Sua chave privada de teste (`sk_test_...`) obtida no [Dashboard do Stripe](https://dashboard.stripe.com/test/apikeys).
3.  **STRIPE_WEBHOOK_SECRET:** Necessário para validar a assinatura HMAC dos eventos enviados pelo Stripe.

```env
# Exemplo de preenchimento manual no .env
DB_PASSWORD=SuaSenhaSegura123
STRIPE_SECRET_KEY=sk_test_51TIi...
STRIPE_WEBHOOK_SECRET=whsec_... # Obtenha via Stripe CLI (ver próximo passo)
```

#### 🔌 Validando Webhooks Localmente (Stripe CLI)
Para que a API aceite as notificações de pagamento do Stripe no seu `localhost`, você deve usar o Stripe CLI como proxy:

1.  **Inicie o túnel:**
    ```bash
    stripe listen --forward-to localhost:3000/billing/webhook
    ```
2.  **Copie o Segredo:** O comando acima imprimirá seu `signing secret` (ex: `whsec_abc123...`). **Cole este valor no seu `.env`** na variável `STRIPE_WEBHOOK_SECRET`.
3. Execute a api com os comandos abaixo:

```bash
cd api-gateway

# Instalar dependências
npm install

# Testes Automatizados
npm run test

# Iniciar o servidor de desenvolvimento
npm run start:dev
```

4.  **Simule um evento:** Em outro terminal, rode o comando abaixo para disparar um teste real:
    ```bash
    stripe trigger payment_intent.succeeded
    ```

#### 🧪 Testando o Fluxo de Faturamento (End-to-End)
Para validar se a API está integrando corretamente com Stripe, Postgres e SQS, execute o seguinte comando no terminal:

```bash
curl -X POST http://localhost:3000/billing/checkout \
     -H "Content-Type: application/json" \
     -d '{"amount": 100}'
```

**Critérios de Sucesso:**
1.  **Response:** Recebimento de um JSON contendo `status: "transaction_initiated"` e o `transactionId`.
2.  **Persistência:** A transação deve aparecer na tabela `transactions` do seu banco de dados.
3.  **Mensageria:** Uma mensagem deve estar disponível na fila `billing-engine-invoice-queue` no Console AWS (SQS).

---

## 🛠️ Comandos Úteis

### Banco de Dados (Postgres)
Como o RDS está em uma Subnet Pública para este laboratório, você pode conectar via DBeaver ou TablePlus usando o endpoint presente no `DB_HOST` do seu `.env`.

### Verificando Fila SQS via CLI

antes de executar o comando esteja na raiz do projeto.

```bash
aws sqs receive-message --queue-url $(grep AWS_SQS_QUEUE_URL api-gateway/.env | cut -d'=' -f2)
```

## 🏗️ Rodando o Worker (Fase 3: Consumo e Idempotência)

O Worker é o motor assíncrono que garante a resiliência do faturamento. Ele utiliza **Idempotência Distribuída** com Redis para evitar cobranças duplicadas.

### Configurando o Ambiente
1. **Entre na pasta do worker:**
   ```bash
   cd billing-worker
   ```
2. **Sincronize o arquivo .env:**
   ```bash
   cp ../api-gateway/.env .env
   ```
   > **Nota:** Certifique-se de que a variável `REDIS_ENDPOINT` aponta para `localhost` para testes locais.

3. **Suba o Redis Local (Docker):**
   Como o ElastiCache da AWS é protegido por VPC, use um container local para gerenciar as travas de idempotência durante o desenvolvimento:
   ```bash
   docker run -d --name billing-redis -p 6379:6379 redis:alpine
   ```

4. **Instale e Inicie:**
   ```bash
   npm install
   npm run dev
   ```

---

## 🧪 Validando o Ciclo de Vida E2E

Para garantir a confiabilidade da **Fase 3**, siga este roteiro de testes:

### 1. O Teste de "Caminho Feliz"
1. Com API e Worker rodando, dispare um checkout:
   ```bash
   curl -X POST http://localhost:3000/billing/checkout \
        -H "Content-Type: application/json" \
        -d '{"amount": 100}'
   ```
2. **O que observar:**
   * **Console Worker:** Log `[CID] Transação finalizada com sucesso`.
   * **Banco (RDS):** O status deve mudar de `PENDING` para `SUCCEEDED` (via SSL).
   * **SQS:** A mensagem deve ser removida automaticamente da fila após o processamento.

### 2. O Teste de Idempotência (Garantia de Resiliência)
Este teste prova que o sistema não cobrará o cliente duas vezes em caso de retentativas do SQS ou do Provedor de pagamento.

1. **Copie o `correlationId` e o `transactionId`** de um log de sucesso anterior.
2. **Simule a duplicidade enviando a mensagem manualmente para o SQS:**
   ```bash
   # Substitua os valores abaixo pelos do seu teste anterior
   aws sqs send-message \
     --queue-url $(grep AWS_SQS_QUEUE_URL api-gateway/.env | cut -d'=' -f2) \
     --message-body '{
       "transactionId": "id-da-transacao-aqui",
       "correlationId": "correlation-id-aqui",
       "amount": 100
     }'
   ```
3. **O que observar:**
   * **Console do Worker:** Deve logar imediatamente: `[CORRELATION_ID] Mensagem duplicada ignorada.`.
   * **Lógica:** O Worker "pesca" a mensagem, pergunta ao Redis se aquele `correlationId` já passou por ali e, como o Redis responde que sim, o Worker deleta a mensagem da fila sem tocar no Banco de Dados ou no Stripe.
   * **Banco (RDS):** O campo `updatedAt` da transação **não** deve ser alterado.


### 3. Consulta de Status via API
Valide se a persistência foi integrada corretamente consultando o novo endpoint:
```bash
curl http://localhost:3000/billing/status/{transactionId_ou_correlationId}
```
**Resultado esperado:**
```json
{
    "transactionId": "...",
    "status": "SUCCEEDED",
    "updatedAt": "2026-04-07T..."
}
```

