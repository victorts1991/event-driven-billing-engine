#!/bin/bash

# 1. Configurações
PREFIX="billing-engine"
REGION="us-east-2"
BUCKET_NAME="st${PREFIX}tf$(openssl rand -hex 3)"
IAM_USER="${PREFIX}-github-actions"

echo "🏁 Iniciando Bootstrap AWS..."

# 2. Criar Bucket S3 para o Terraform State
echo "📦 Criando Bucket para o State..."
aws s3 mb s3://$BUCKET_NAME --region $REGION

# 3. Criar Usuário IAM e dar permissões
echo "🔑 Criando Usuário e gerando credenciais..."
aws iam create-user --user-name $IAM_USER
aws iam attach-user-policy --user-name $IAM_USER --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Gerar chaves de acesso
USER_JSON=$(aws iam create-access-key --user-name $IAM_USER)
ACCESS_KEY=$(echo $USER_JSON | jq -r '.AccessKey.AccessKeyId')
SECRET_KEY=$(echo $USER_JSON | jq -r '.AccessKey.SecretAccessKey')

# 4. Resultado Final
echo "----------------------------------------------------"
echo "✅ BOOTSTRAP CONCLUÍDO!"
echo "----------------------------------------------------"
echo "1. BUCKET NAME (Coloque no backend do main.tf):"
echo "$BUCKET_NAME"
echo ""
echo "2. GITHUB SECRETS (Adicione no seu repositório):"
echo "AWS_ACCESS_KEY_ID: $ACCESS_KEY"
echo "AWS_SECRET_ACCESS_KEY: $SECRET_KEY"
echo "AWS_REGION: $REGION"
echo "----------------------------------------------------"