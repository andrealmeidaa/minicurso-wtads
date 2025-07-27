#!/bin/bash -xe

# Script de deploy para o Task Project com Nginx
echo "=== Iniciando deploy do Task Project ==="

# Atualizar sistema
apt update -y
apt install -y nginx mysql-server python3-pip python3-venv git pkg-config libmysqlclient-dev

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
if [ ! -d "/home/ubuntu/minicurso-wtads" ]; then
    cd /home/ubuntu
    git clone https://github.com/andrealmeidaa/minicurso-wtads.git
else
    cd /home/ubuntu/minicurso-wtads
    git pull origin main
fi

cd /home/ubuntu/minicurso-wtads/task_project

# Criar ambiente virtual Python
python3 -m venv venv
source venv/bin/activate

# Instalar dependências Python no ambiente virtual
pip install -r requirements_simple.txt

# Configurar MySQL
systemctl start mysql
systemctl enable mysql

# Criar banco de dados e usuário
mysql -u root -e "CREATE DATABASE IF NOT EXISTS taskdb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -e "CREATE USER IF NOT EXISTS 'taskapp'@'localhost' IDENTIFIED BY 'task@123';"
mysql -u root -e "GRANT ALL PRIVILEGES ON taskdb.* TO 'taskapp'@'localhost';"
mysql -u root -e "FLUSH PRIVILEGES;"

sed -i 's/.*bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl enable mysql
service mysql restart

# Configurar arquivo .env
cat > .env << EOF
SECRET_KEY=$(venv/bin/python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
DEBUG=False
ALLOWED_HOSTS=*
DB_NAME=taskdb
DB_USER=taskapp
DB_PASSWORD=task@123
DB_HOST=localhost
DB_PORT=3306
EOF

# Executar migrações
venv/bin/python manage.py makemigrations
venv/bin/python manage.py migrate

# Coletar arquivos estáticos
venv/bin/python manage.py collectstatic --noinput

# Criar superusuário se não existir
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
chown -R www-data:www-data /home/ubuntu/minicurso-wtads/task_project
chmod +x /home/ubuntu/minicurso-wtads/task_project/gunicorn.conf.py

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
systemctl status mysql --no-pager -l
systemctl status task_project --no-pager -l
systemctl status nginx --no-pager -l

echo "=== Deploy concluído! ==="
echo "Aplicação disponível em: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "Admin: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/admin"
echo "Usuário admin: admin"
echo "Senha admin: admin123"
