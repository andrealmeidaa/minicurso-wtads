#!/bin/bash

# Script para iniciar o projeto localmente

echo "=== Iniciando Task Project ==="

# Verificar se o .env existe
if [ ! -f ".env" ]; then
    echo "Criando arquivo .env..."
    cp .env.example .env
fi

# Instalar dependências
echo "Instalando dependências..."
pip install -r requirements_simple.txt

# Executar migrações
echo "Executando migrações..."
python manage.py makemigrations
python manage.py migrate

# Criar superusuário se necessário
echo "Verificando superusuário..."
python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@localhost', 'admin123')
    print('Superusuário criado: admin/admin123')
else:
    print('Superusuário já existe')
"

# Iniciar servidor
echo "Iniciando servidor..."
echo "Aplicação disponível em: http://localhost:8000"
echo "Admin disponível em: http://localhost:8000/admin"
echo "Usuário: admin | Senha: admin123"
echo ""

python manage.py runserver 0.0.0.0:8000
