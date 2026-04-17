#!/bin/bash

# --- Configurações de Caminho ---
TF_DIR="./terraform"
ENV_PATH="./api-gateway/.env"

echo "🚀 Coletando outputs do Terraform em $TF_DIR..."

# Verifica se o jq está instalado
if ! command -v jq &> /dev/null; then
    echo "❌ Erro: 'jq' não encontrado. Instale com 'brew install jq'"
    exit 1
fi

# CAPTURA AS CREDENCIAIS DO SEU MAC (O PULO DO GATO)
AWS_KEY=$(aws configure get aws_access_key_id)
AWS_SECRET=$(aws configure get aws_secret_access_key)

# Entra na pasta do terraform para pegar os outputs
cd $TF_DIR
TF_OUTPUTS=$(terraform output -json)
cd - > /dev/null

# Função auxiliar para extrair valores
get_tf_val() {
  echo "$TF_OUTPUTS" | jq -r ".$1.value // empty"
}

# GERA O .ENV COM AS CHAVES AWS
cat <<EOF > $ENV_PATH
# --- Gerado Automaticamente via Terraform ---
PORT=3000
NODE_ENV=development

# --- Database (RDS) ---
DB_HOST=$(get_tf_val "db_endpoint")
DB_PORT=5432
DB_USERNAME=$(get_tf_val "db_user")
DB_DATABASE=$(get_tf_val "db_name")
DB_PASSWORD=SuaSenhaSegura123

# --- Stripe ---
STRIPE_SECRET_KEY=sk_test_insira_sua_chave_aqui
STRIPE_WEBHOOK_SECRET=whsec_insira_sua_chave_aqui

# --- AWS / Messaging ---
AWS_REGION=us-east-2
AWS_ACCESS_KEY_ID=$AWS_KEY
AWS_SECRET_ACCESS_KEY=$AWS_SECRET
AWS_SQS_QUEUE_URL=$(get_tf_val "sqs_url")
REDIS_ENDPOINT=$(get_tf_val "redis_endpoint")

# --- Cluster Info ---
EKS_CLUSTER_NAME=$(get_tf_val "cluster_name")
EKS_ENDPOINT=$(get_tf_val "cluster_endpoint")
EOF

echo "✅ .env atualizado com SUCESSO em $ENV_PATH"