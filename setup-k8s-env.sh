#!/bin/bash

# --- Configurações de Caminho ---
TF_DIR="./terraform"
K8S_DIR="./k8s"

echo "🚀 Coletando outputs do Terraform em $TF_DIR..."

# Verifica dependências
if ! command -v jq &> /dev/null; then
    echo "❌ Erro: 'jq' não encontrado. Instale com 'brew install jq'"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo "❌ Erro: 'kubectl' não encontrado."
    exit 1
fi

# Captura credenciais AWS do perfil local
AWS_KEY=$(aws configure get aws_access_key_id)
AWS_SECRET=$(aws configure get aws_secret_access_key)

# Captura outputs do Terraform
cd $TF_DIR
TF_OUTPUTS=$(terraform output -json)
cd - > /dev/null

get_tf_val() {
  echo "$TF_OUTPUTS" | jq -r ".$1.value // empty"
}

# Extrai os valores
export DB_HOST=$(get_tf_val "db_endpoint")
export DB_USERNAME=$(get_tf_val "db_user")
export DB_DATABASE=$(get_tf_val "db_name")
export AWS_REGION="us-east-2"
export AWS_SQS_QUEUE_URL=$(get_tf_val "sqs_url")
export REDIS_ENDPOINT=$(get_tf_val "redis_endpoint")
export EKS_CLUSTER_NAME=$(get_tf_val "cluster_name")
export AWS_ACCESS_KEY_ID=$AWS_KEY
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET
export ECR_API_URL=$(get_tf_val "ecr_api_url")
export ECR_WORKER_URL=$(get_tf_val "ecr_worker_url")

# Solicita os segredos que não estão no Terraform
echo ""
echo "🔑 Insira os segredos manualmente (não ficam em nenhum arquivo):"
read -s -p "   DB_PASSWORD: " DB_PASSWORD && export DB_PASSWORD && echo ""
read -s -p "   STRIPE_SECRET_KEY: " STRIPE_SECRET_KEY && export STRIPE_SECRET_KEY && echo ""
read -s -p "   STRIPE_WEBHOOK_SECRET: " STRIPE_WEBHOOK_SECRET && export STRIPE_WEBHOOK_SECRET && echo ""

echo ""
echo "📦 Aplicando ConfigMap e Secrets no Kubernetes..."

# Aplica ConfigMap e Secrets com envsubst
envsubst < $K8S_DIR/configmap.yaml | kubectl apply -f -
envsubst < $K8S_DIR/secrets.yaml | kubectl apply -f -

echo "✅ ConfigMap e Secrets aplicados com SUCESSO no cluster!"