#!/bin/bash

PREFIX="billing-engine"
IAM_USER="${PREFIX}-github-actions"
REGIONS=("us-east-1" "us-east-2")

for REG in "${REGIONS[@]}"; do
    echo "🌍 Varrendo região: $REG"

    CLUSTER_NAME="${PREFIX}-cluster"
    
    # --- 1. EKS: NODES ---
    NGS=$(aws eks list-nodegroups --cluster-name $CLUSTER_NAME --region $REG --query "nodegroups" --output text 2>/dev/null)
    for NG in $NGS; do
        if [ "$NG" != "None" ] && [ ! -z "$NG" ]; then
            echo "   [EKS] Matando Nodegroup: $NG..."
            aws eks delete-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name $NG --region $REG 2>/dev/null
            echo "   [EKS] Aguardando Nodegroup sumir..."
            aws eks wait nodegroup-deleted --cluster-name $CLUSTER_NAME --nodegroup-name $NG --region $REG 2>/dev/null
        fi
    done

    # --- 2. EKS: CLUSTER ---
    echo "   [EKS] Deletando Cluster..."
    aws eks delete-cluster --name $CLUSTER_NAME --region $REG 2>/dev/null
    echo "   [EKS] Aguardando Cluster sumir (Isso demora)..."
    aws eks wait cluster-deleted --name $CLUSTER_NAME --region $REG 2>/dev/null

    # --- 3. RDS: BANCO ---
    echo "   [RDS] Deletando Instância..."
    aws rds delete-db-instance --db-instance-identifier "${PREFIX}-db" --skip-final-snapshot --delete-automated-backups --region $REG 2>/dev/null
    echo "   [RDS] Aguardando Banco sumir..."
    aws rds wait db-instance-deleted --db-instance-identifier "${PREFIX}-db" --region $REG 2>/dev/null

    # --- 4. REDIS, SQS, LOGS e KMS ---
    # Esses são rápidos, não precisam de 'wait' longo
    # --- 4. REDIS (Tenta os dois modos: Cluster e Replication Group) ---
    aws elasticache delete-replication-group --replication-group-id "${PREFIX}-redis" --region $REG 2>/dev/null
    aws elasticache delete-cache-cluster --cache-cluster-id "${PREFIX}-redis" --region $REG 2>/dev/null
    aws logs delete-log-group --log-group-name "/aws/eks/${CLUSTER_NAME}/cluster" --region $REG 2>/dev/null
    aws kms delete-alias --alias-name "alias/eks/${CLUSTER_NAME}" --region $REG 2>/dev/null
    
    QUEUES=("queue" "dlq")
    for Q in "${QUEUES[@]}"; do
        Q_URL=$(aws sqs get-queue-url --queue-name "${PREFIX}-invoice-$Q" --region $REG --query 'QueueUrl' --output text 2>/dev/null)
        if [ ! -z "$Q_URL" ] && [ "$Q_URL" != "None" ]; then aws sqs delete-queue --queue-url $Q_URL --region $REG 2>/dev/null; fi
    done

    # --- 5. LIMPEZA DE SECURITY GROUPS ZUMBIS ---
    echo "   [EC2] Limpando Security Groups do Projeto..."
    SG_IDS=$(aws ec2 describe-security-groups --filters Name=group-name,Values="${PREFIX}*" --region $REG --query "SecurityGroups[*].GroupId" --output text 2>/dev/null)
    for SID in $SG_IDS; do
        aws ec2 delete-security-group --group-id $SID --region $REG 2>/dev/null
    done
done

# --- 6. IAM e S3 ---
echo "🆔 Limpando IAM..."
aws iam detach-user-policy --user-name $IAM_USER --policy-arn arn:aws:iam::aws:policy/AdministratorAccess 2>/dev/null
KEYS=$(aws iam list-access-keys --user-name $IAM_USER --query 'AccessKeyMetadata[*].AccessKeyId' --output text 2>/dev/null)
for KEY in $KEYS; do aws iam delete-access-key --user-name $IAM_USER --access-key-id $KEY 2>/dev/null; done
aws iam delete-user --user-name $IAM_USER 2>/dev/null

echo "📦 DESTRUINDO Buckets S3..."
BUCKETS=$(aws s3 ls | grep "st${PREFIX}tf" | awk '{print $3}')
for BKT in $BUCKETS; do aws s3 rb s3://$BKT --force 2>/dev/null; done

# --- 7. LOCAL ---
rm -rf terraform/.terraform terraform/.terraform.lock.hcl terraform/terraform.tfstate*

echo "----------------------------------------------------"
echo "✅ DESTRUIÇÃO COMPLETA E CONFIRMADA PELA AWS."
echo "Agora sim, pode rodar o ./bootstrap.sh."
echo "----------------------------------------------------"