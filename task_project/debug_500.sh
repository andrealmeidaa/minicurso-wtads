#!/bin/bash

# Script para diagnosticar erros 500 na aplicação Django
echo "=== Diagnóstico de Erro 500 - Task Project ==="
echo "Data: $(date)"
echo ""

# 1. Verificar status dos serviços
echo "1. === STATUS DOS SERVIÇOS ==="
echo "Task Project:"
systemctl status task_project --no-pager -l || echo "❌ Serviço task_project com problemas"
echo ""

echo "Nginx:"
systemctl status nginx --no-pager -l || echo "❌ Serviço nginx com problemas"
echo ""

# 2. Verificar logs do Django/Gunicorn
echo "2. === LOGS DO DJANGO/GUNICORN (últimas 50 linhas) ==="
journalctl -u task_project -n 50 --no-pager || echo "❌ Não foi possível acessar logs do task_project"
echo ""

# 3. Verificar logs do Nginx
echo "3. === LOGS DO NGINX ==="
echo "Nginx Error Log (últimas 20 linhas):"
tail -20 /var/log/nginx/error.log 2>/dev/null || echo "❌ Arquivo de log não encontrado"
echo ""

echo "Task Project Error Log (últimas 20 linhas):"
tail -20 /var/log/nginx/task_project_error.log 2>/dev/null || echo "❌ Arquivo de log específico não encontrado"
echo ""

# 4. Verificar conectividade com banco de dados
echo "4. === TESTE DE CONECTIVIDADE ==="
echo "Testando Django shell..."
cd /opt/minicurso-wtads/task_project 2>/dev/null || cd /workspaces/minicurso-wtads/task_project

if [ -f "venv/bin/python" ]; then
    echo "Testando conexão com banco de dados..."
    venv/bin/python manage.py shell -c "
import django
from django.db import connection
try:
    with connection.cursor() as cursor:
        cursor.execute('SELECT 1')
        print('✓ Conexão com banco de dados OK')
except Exception as e:
    print(f'❌ Erro de conexão com banco: {e}')
" 2>&1
else
    echo "❌ Ambiente virtual não encontrado"
fi
echo ""

# 5. Verificar configurações AWS (se aplicável)
echo "5. === CONFIGURAÇÕES AWS ==="
if [ -f ".env" ]; then
    echo "Configurações do .env:"
    grep -E "(USE_AWS_SECRETS|AWS_REGION|AWS_SECRET_NAME)" .env 2>/dev/null || echo "Configurações AWS não encontradas no .env"
    
    USE_AWS_SECRETS=$(grep "USE_AWS_SECRETS" .env 2>/dev/null | cut -d'=' -f2)
    if [ "$USE_AWS_SECRETS" = "True" ]; then
        echo ""
        echo "Testando acesso ao AWS Secrets Manager..."
        AWS_SECRET_NAME=$(grep "AWS_SECRET_NAME" .env 2>/dev/null | cut -d'=' -f2)
        AWS_REGION=$(grep "AWS_REGION" .env 2>/dev/null | cut -d'=' -f2)
        
        if command -v aws &> /dev/null; then
            aws secretsmanager describe-secret --secret-id "$AWS_SECRET_NAME" --region "$AWS_REGION" &>/dev/null && \
            echo "✓ Acesso ao AWS Secrets Manager OK" || \
            echo "❌ Erro de acesso ao AWS Secrets Manager"
        else
            echo "❌ AWS CLI não instalado"
        fi
    fi
else
    echo "❌ Arquivo .env não encontrado"
fi
echo ""

# 6. Verificar permissões
echo "6. === PERMISSÕES ==="
echo "Permissões do diretório da aplicação:"
ls -la /opt/minicurso-wtads/task_project/ 2>/dev/null | head -5 || \
ls -la /workspaces/minicurso-wtads/task_project/ 2>/dev/null | head -5 || \
echo "❌ Diretório da aplicação não encontrado"
echo ""

# 7. Verificar se DEBUG está ativado temporariamente
echo "7. === SUGESTÕES DE DEBUGGING ==="
echo "Para debug temporário, execute:"
echo "1. Ative DEBUG temporariamente:"
echo "   echo 'DEBUG=True' >> .env"
echo "   systemctl restart task_project"
echo ""
echo "2. Execute Django em modo debug:"
echo "   cd /opt/minicurso-wtads/task_project"
echo "   source venv/bin/activate"
echo "   python manage.py runserver 0.0.0.0:8001"
echo ""
echo "3. Verifique logs em tempo real:"
echo "   journalctl -u task_project -f"
echo ""

# 8. Teste de sintaxe Django
echo "8. === TESTE DE SINTAXE ==="
if [ -f "venv/bin/python" ]; then
    echo "Verificando sintaxe do Django..."
    venv/bin/python manage.py check 2>&1
else
    echo "❌ Não foi possível verificar sintaxe - ambiente virtual não encontrado"
fi

echo ""
echo "=== FIM DO DIAGNÓSTICO ==="
