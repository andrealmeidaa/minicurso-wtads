#!/bin/bash

# Script para configurar AWS Secrets Manager para o Task Project
# Execute este script antes do deploy para criar o secret necessário

set -e

# Configurações padrão
SECRET_NAME="task-project/prod"
REGION="us-east-1"
DESCRIPTION="Database and Django configuration for Task Project"

# Verificar se AWS CLI está configurado
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ Erro: AWS CLI não está configurado ou não tem permissões adequadas"
    echo "Configure com: aws configure"
    exit 1
fi

echo "=== Configurando AWS Secrets Manager para Task Project ==="
echo "Secret Name: $SECRET_NAME"
echo "Region: $REGION"

# Solicitar informações do RDS
echo ""
echo "Digite as informações do seu RDS MySQL:"
read -p "RDS Endpoint (ex: mydb.cluster-xyz.us-east-1.rds.amazonaws.com): " RDS_HOST
read -p "Database Name [taskdb]: " DB_NAME
DB_NAME=${DB_NAME:-taskdb}
read -p "Username [admin]: " DB_USER
DB_USER=${DB_USER:-admin}
read -s -p "Password: " DB_PASSWORD
echo ""
read -p "Port [3306]: " DB_PORT
DB_PORT=${DB_PORT:-3306}

# Gerar secret key para Django
DJANGO_SECRET=$(python3 -c "
import secrets
import string
chars = string.ascii_letters + string.digits + '!@#$%^&*(-_=+)'
print(''.join(secrets.choice(chars) for _ in range(50)))
")

# Criar JSON do secret
SECRET_JSON=$(cat <<EOF
{
  "username": "$DB_USER",
  "password": "$DB_PASSWORD", 
  "host": "$RDS_HOST",
  "port": $DB_PORT,
  "dbname": "$DB_NAME",
  "django_secret_key": "$DJANGO_SECRET"
}
EOF
)

echo ""
echo "Criando secret no AWS Secrets Manager..."

# Verificar se o secret já existe
if aws secretsmanager describe-secret --secret-id "$SECRET_NAME" --region "$REGION" > /dev/null 2>&1; then
    echo "Secret já existe. Atualizando..."
    aws secretsmanager update-secret \
        --secret-id "$SECRET_NAME" \
        --secret-string "$SECRET_JSON" \
        --region "$REGION"
    echo "✓ Secret atualizado com sucesso!"
else
    echo "Criando novo secret..."
    aws secretsmanager create-secret \
        --name "$SECRET_NAME" \
        --description "$DESCRIPTION" \
        --secret-string "$SECRET_JSON" \
        --region "$REGION"
    echo "✓ Secret criado com sucesso!"
fi

echo ""
echo "=== Configuração concluída! ==="
echo ""
echo "Para usar este secret na sua instância EC2:"
echo "1. Certifique-se de que a instância tem uma IAM Role com permissões:"
echo "   - secretsmanager:GetSecretValue"
echo "   - secretsmanager:DescribeSecret"
echo ""
echo "2. Execute o deploy com as variáveis:"
echo "   export AWS_REGION=$REGION"
echo "   export AWS_SECRET_NAME=$SECRET_NAME"
echo "   sudo -E ./deploy.sh"
echo ""
echo "Exemplo de IAM Policy necessária:"
cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret"
            ],
            "Resource": "arn:aws:secretsmanager:$REGION:*:secret:$SECRET_NAME*"
        }
    ]
}
EOF

echo ""
echo "🔐 Secret ARN: arn:aws:secretsmanager:$REGION:$(aws sts get-caller-identity --query Account --output text):secret:$SECRET_NAME"
