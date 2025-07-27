#!/bin/bash -xe

# Script de deploy para o Task Project com AWS RDS e Secrets Manager
echo "=== Iniciando deploy do Task Project na AWS ==="

# Verificar se as variáveis AWS estão definidas
if [ -z "$AWS_REGION" ]; then
    export AWS_REGION="us-east-1"
    echo "AWS_REGION não definido, usando padrão: us-east-1"
fi

if [ -z "$AWS_SECRET_NAME" ]; then
    export AWS_SECRET_NAME="task-project/prod"
    echo "AWS_SECRET_NAME não definido, usando padrão: task-project/prod"
fi

# Atualizar sistema
apt update -y
apt install -y nginx python3-pip python3-venv git pkg-config libmysqlclient-dev awscli

# Criar usuário www-data se não existir
if ! id -u www-data > /dev/null 2>&1; then
    useradd -r -s /bin/false www-data
fi

# Criar diretórios necessários
mkdir -p /var/log/gunicorn
mkdir -p /var/run/gunicorn
chown www-data:www-data /var/log/gunicorn
chown www-data:www-data /var/run/gunicorn

# Clonar ou atualizar projeto
if [ ! -d "/opt/minicurso-wtads" ]; then
    cd /opt
    git clone https://github.com/andrealmeidaa/minicurso-wtads.git
    git switch deploy_aws_rds
else
    cd /opt/minicurso-wtads
    git pull origin deploy_aws_rds || git switch deploy_aws_rds
fi

cd /opt/minicurso-wtads/task_project

# Criar ambiente virtual Python
python3 -m venv venv
source venv/bin/activate

# Instalar dependências Python no ambiente virtual
pip install -r requirements_simple.txt

# Verificar conectividade com AWS Secrets Manager
echo "Verificando acesso ao AWS Secrets Manager..."
if aws secretsmanager describe-secret --secret-id "$AWS_SECRET_NAME" --region "$AWS_REGION" > /dev/null 2>&1; then
    echo "✓ Acesso ao AWS Secrets Manager confirmado"
    USE_AWS_SECRETS=True
else
    echo "⚠️  Aviso: Não foi possível acessar o AWS Secrets Manager"
    echo "   Certifique-se de que:"
    echo "   1. A instância EC2 tem uma IAM Role com permissões adequadas"
    echo "   2. O secret '$AWS_SECRET_NAME' existe na região '$AWS_REGION'"
    echo "   3. O secret contém as chaves: username, password, host, port, dbname, django_secret_key"
    USE_AWS_SECRETS=False
fi

# Configurar arquivo .env
cat > .env << EOF
SECRET_KEY=fallback-secret-key-$(date +%s)
DEBUG=False
ALLOWED_HOSTS=*
USE_AWS_SECRETS=$USE_AWS_SECRETS
AWS_REGION=$AWS_REGION
AWS_SECRET_NAME=$AWS_SECRET_NAME

# Fallback database config (usado apenas se AWS Secrets falhar)
DB_NAME=taskdb
DB_USER=taskapp
DB_PASSWORD=task@123
DB_HOST=localhost
DB_PORT=3306
EOF

# Executar migrações
echo "Executando migrações do Django..."
venv/bin/python manage.py makemigrations
venv/bin/python manage.py migrate

# Coletar arquivos estáticos
echo "Coletando arquivos estáticos..."
venv/bin/python manage.py collectstatic --noinput

# Criar superusuário se não existir
echo "Verificando/criando superusuário..."
venv/bin/python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@localhost', 'admin123')
    print('Superusuário criado: admin/admin123')
else:
    print('Superusuário já existe')
"

# Configurar permissões
chown -R www-data:www-data /opt/minicurso-wtads/task_project
chmod +x /opt/minicurso-wtads/task_project/gunicorn.conf.py

# Configurar systemd service
cp task_project.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable task_project
systemctl start task_project

# Configurar Nginx
cp nginx.conf /etc/nginx/sites-available/task_project
ln -sf /etc/nginx/sites-available/task_project /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Testar configuração do Nginx
nginx -t

# Reiniciar serviços
systemctl restart nginx
systemctl restart task_project

# Verificar status
echo "=== Status dos serviços ==="
systemctl status task_project --no-pager -l
systemctl status nginx --no-pager -l

echo "=== Deploy concluído! ==="

# Obter IP público da instância
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "localhost")

echo "=== Informações de Acesso ==="
echo "Aplicação disponível em: http://$PUBLIC_IP"
echo "Admin disponível em: http://$PUBLIC_IP/admin"
echo "Usuário admin: admin"
echo "Senha admin: admin123"
echo ""
echo "=== Configuração AWS ==="
echo "Região AWS: $AWS_REGION"
echo "Secret Manager: $AWS_SECRET_NAME"
echo "Usando AWS Secrets: $USE_AWS_SECRETS"
echo ""
if [ "$USE_AWS_SECRETS" = "True" ]; then
    echo "✓ Aplicação configurada para usar AWS RDS e Secrets Manager"
else
    echo "⚠️  Aplicação usando configurações de fallback"
    echo "   Para usar AWS RDS e Secrets Manager:"
    echo "   1. Configure uma IAM Role na instância EC2"
    echo "   2. Crie o secret no AWS Secrets Manager"
    echo "   3. Execute o deploy novamente"
fi
