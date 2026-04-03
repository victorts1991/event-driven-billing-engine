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
* **Mensageria:** AWS SQS (Emulado via **LocalStack** para desenvolvimento local)
* **Banco de Dados:** PostgreSQL (Persistência Transacional)
* **Cache & Idempotência:** Redis
* **Pagamentos:** Stripe SDK (Integration em Test Mode)
* **Infraestrutura:** Kubernetes (K8s) & Terraform (IaC)
* **CI/CD:** GitHub Actions (Pipelines de Testes, Build e Deploy)
* **Testes:** Jest & Supertest (Unitários e E2E)
* **Containerização:** Docker & Docker Compose

---

## 🗺️ Roadmap de Desenvolvimento

### 1. Infraestrutura como Código (Terraform)
- [ ] Script de Bootstrap para Backend Remoto (S3/Terraform State).
- [ ] Módulo de Mensageria (SQS Queues + Dead Letter Queues).
- [ ] Módulo de Banco de Dados e Cache (RDS/Postgres + ElastiCache/Redis).
- [ ] Provisionamento de Cluster EKS/AKS ou ambiente local via Terraform.

### 2. Qualidade e Testes Automatizados (QA)
- [ ] **Testes Unitários:** Cobertura de lógica de negócio e serviços de integração.
- [ ] **Testes de Integração:** Validação da comunicação com Postgres e Redis usando Docker.
- [ ] **Testes E2E:** Simulação do fluxo completo: Request -> Fila -> Worker -> Stripe -> Webhook.
- [ ] **Testes de Resiliência:** Validação do comportamento da DLQ (Dead Letter Queue) em caso de falhas.

### 3. API Gateway & Mensageria (NestJS)
- [ ] Setup do projeto NestJS com suporte a TypeScript.
- [ ] Implementação do módulo Stripe (Payment Intent Creation).
- [ ] Lógica de Injeção de **Correlation ID** em todos os logs e eventos.
- [ ] Producer SQS para despacho assíncrono de intenções de compra.
- [ ] Endpoint de Webhook seguro com validação de assinatura do Stripe.

### 4. Worker Consumer (Resiliência)
- [ ] Implementação do Consumer SQS (Polling ou Long Polling).
- [ ] Camada de **Idempotência com Redis** (Verificação de ID de transação).
- [ ] Processamento de confirmação e atualização de status no PostgreSQL.
- [ ] Estratégia de *Retry* exponencial para falhas temporárias na API do Stripe.

### 5. Automação Full CI/CD (GitHub Actions)
- [ ] **CI:** Pipeline para execução de Linting e Suíte de Testes (Unit/Int).
- [ ] **Build:** Geração de imagens Docker multi-stage e push para Registro (ACR/ECR).
- [ ] **CD:** Deploy idempotente no Kubernetes injetando secrets dinâmicos do Terraform.
- [ ] **Security Scan:** Verificação de vulnerabilidades nas dependências e imagens.

---