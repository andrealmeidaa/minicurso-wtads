# Sistema de Gerenciamento de Tasks

Um sistema Django para gerenciamento de tarefas pessoais com interface moderna usando Bulma CSS.

## Características

- ✅ Autenticação de usuários obrigatória
- ✅ CRUD completo de tasks
- ✅ Interface responsiva com Bulma CSS
- ✅ Class-based views
- ✅ Sistema de busca e filtros
- ✅ Paginação
- ✅ Suporte ao MySQL
- ✅ Configuração via variáveis de ambiente

## Pré-requisitos

- Python 3.8+
- pip

## Instalação Rápida (Desenvolvimento)

Para desenvolvimento local, use o script automatizado:

```bash
cd task_project
chmod +x start.sh
./start.sh
```

O script irá:
- Criar arquivo `.env` se não existir
- Instalar dependências
- Executar migrações
- Criar superusuário (admin/admin123)
- Iniciar servidor em http://localhost:8000

## Deploy em Produção AWS

### Deploy com AWS RDS e Secrets Manager (Recomendado)

Para deploy em instância EC2 com AWS RDS MySQL:

1. **Configure o AWS Secrets Manager:**
   ```bash
   # Execute localmente (com AWS CLI configurado)
   cd task_project
   chmod +x setup_aws_secrets.sh
   ./setup_aws_secrets.sh
   ```

2. **Configure IAM Role na instância EC2:**
   - Anexe uma IAM Role à instância EC2 com permissões:
     - `secretsmanager:GetSecretValue`
     - `secretsmanager:DescribeSecret`

3. **Execute o deploy:**
   ```bash
   # Na instância EC2
   export AWS_REGION="us-east-1"  # sua região
   export AWS_SECRET_NAME="task-project/prod"  # nome do secret
   sudo -E ./deploy.sh
   ```

### Deploy Tradicional (Nginx + MySQL local)

Para deploy em servidor Ubuntu/Debian com MySQL local:

```bash
cd task_project
chmod +x deploy.sh
sudo ./deploy.sh
```

**O script de deploy AWS irá:**
- Instalar Nginx, AWS CLI e dependências
- Criar ambiente virtual Python
- Verificar conectividade com AWS Secrets Manager
- Configurar aplicação para usar AWS RDS
- Configurar Gunicorn como serviço systemd
- Configurar Nginx como proxy reverso
- Criar superusuário admin
- Iniciar todos os serviços

**O script de deploy tradicional irá:**
- Instalar Nginx, MySQL e dependências
- Criar ambiente virtual Python
- Configurar banco de dados MySQL local
- Configurar Gunicorn como serviço systemd
- Configurar Nginx como proxy reverso
- Criar superusuário admin
- Iniciar todos os serviços

## Instalação Manual (Desenvolvimento com SQLite)

1. **Clone o repositório e navegue até o diretório:**
   ```bash
   cd task_project
   ```

2. **Crie um ambiente virtual:**
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # Linux/Mac
   # ou
   venv\Scripts\activate     # Windows
   ```

3. **Instale as dependências:**
   ```bash
   pip install -r requirements_simple.txt
   ```

4. **Configure as variáveis de ambiente (opcional):**
   ```bash
   cp .env.example .env
   ```
   
   Para desenvolvimento com SQLite, você pode usar as configurações padrão.

5. **Execute as migrações:**
   ```bash
   python manage.py makemigrations
   python manage.py migrate
   ```

6. **Crie um superusuário:**
   ```bash
   python manage.py createsuperuser
   ```

7. **Execute o servidor:**
   ```bash
   python manage.py runserver
   ```

## Configuração para Produção com MySQL

Se você quiser usar MySQL em produção:

1. **Instale o MySQL e configure:**
   ```bash
   sudo apt-get install mysql-server
   sudo mysql_secure_installation
   ```

2. **Crie o banco de dados:**
   ```sql
   CREATE DATABASE task_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   CREATE USER 'taskapp'@'localhost' IDENTIFIED BY 'task@123';
   GRANT ALL PRIVILEGES ON task_db.* TO 'taskapp'@'localhost';
   FLUSH PRIVILEGES;
   ```

3. **Configure o .env:**
   ```env
   DB_NAME=task_db
   DB_USER=taskapp
   DB_PASSWORD=task@123
   DB_HOST=localhost
   DB_PORT=3306
   ```

4. **Modifique settings.py** para usar a configuração MySQL comentada

5. **Instale mysqlclient:**
   ```bash
   pip install mysqlclient
   ```

## Uso

1. **Acesse o sistema em:** http://localhost:8000
2. **Faça login** com as credenciais criadas
3. **Gerencie suas tasks:**
   - Criar novas tasks
   - Visualizar detalhes
   - Editar tasks existentes
   - Marcar como concluídas
   - Excluir tasks
   - Buscar e filtrar

## Funcionalidades

### Views Implementadas
- `TaskListView`: Lista paginada com busca e filtros
- `TaskDetailView`: Detalhes completos da task
- `TaskCreateView`: Criação de novas tasks
- `TaskUpdateView`: Edição de tasks existentes
- `TaskDeleteView`: Confirmação e exclusão

### Recursos de Interface
- Design responsivo com Bulma CSS
- Icons com Font Awesome
- Mensagens de feedback
- Navegação breadcrumb
- Sistema de notificações

### Segurança
- Autenticação obrigatória
- Usuários só acessam suas próprias tasks
- CSRF protection
- Configurações via variáveis de ambiente
- Integração com AWS Secrets Manager para produção

## Arquitetura de Produção

### Arquitetura AWS (Recomendada)
```
Internet → ALB/CloudFront → EC2 → Nginx → Gunicorn → Django → RDS MySQL
                                                             ↓
                                                    Secrets Manager
```

### Arquitetura Tradicional
```
Internet → Nginx (Port 80) → Gunicorn (Port 8000) → Django → MySQL Local
```

### Componentes AWS:
- **EC2**: Instância para aplicação Django
- **RDS MySQL**: Banco de dados gerenciado
- **Secrets Manager**: Gerenciamento seguro de credenciais
- **IAM Role**: Permissões para acessar recursos AWS
- **Nginx**: Servidor web e proxy reverso
- **Gunicorn**: Servidor WSGI para Django
- **Django**: Framework da aplicação
- **Systemd**: Gerenciamento de serviços

### Componentes Tradicionais:
- **Nginx**: Servidor web e proxy reverso
- **Gunicorn**: Servidor WSGI para Django
- **Django**: Framework da aplicação
- **MySQL**: Banco de dados local
- **Systemd**: Gerenciamento de serviços

### Arquivos de Configuração:
- `nginx.conf`: Configuração do Nginx
- `gunicorn.conf.py`: Configuração do Gunicorn
- `task_project.service`: Serviço systemd
- `deploy.sh`: Script de deploy automatizado (AWS + tradicional)
- `setup_aws_secrets.sh`: Script para configurar AWS Secrets Manager
- `aws_config.py`: Módulo de integração com AWS
- `start.sh`: Script para desenvolvimento local

## Estrutura do Projeto

```
task_project/
├── manage.py
├── requirements_simple.txt    # Dependências principais
├── requirements.txt          # Dependências completas (Jupyter/dev)
├── .env.example             # Exemplo de configuração
├── deploy.sh               # Script de deploy para produção
├── setup_aws_secrets.sh    # Script para configurar AWS Secrets Manager
├── aws_config.py          # Módulo de integração com AWS
├── start.sh               # Script para desenvolvimento
├── gunicorn.conf.py       # Configuração do Gunicorn
├── nginx.conf            # Configuração do Nginx
├── task_project.service  # Serviço systemd
├── task_project/
│   ├── settings.py
│   ├── urls.py
│   └── ...
└── tasks/
    ├── models.py
    ├── views.py
    ├── forms.py
    ├── urls.py
    ├── admin.py
    └── templates/
        ├── base.html
        ├── registration/
        │   └── login.html
        └── tasks/
            ├── task_list.html
            ├── task_detail.html
            ├── task_form.html
            └── task_confirm_delete.html
```

## Dependências

### Produção:
- **Django 5.2+**: Framework web
- **mysqlclient**: Driver MySQL para Python
- **gunicorn**: Servidor WSGI
- **python-dotenv**: Gerenciamento de variáveis de ambiente
- **boto3**: SDK AWS para Python
- **PyMySQL**: Driver MySQL alternativo (compatível com RDS)

### Frontend:
- **Bulma CSS**: Framework CSS (via CDN)
- **Font Awesome**: Icons (via CDN)

### Infraestrutura AWS:
- **EC2**: Instância para aplicação
- **RDS MySQL**: Banco de dados gerenciado
- **Secrets Manager**: Gerenciamento de credenciais
- **IAM**: Controle de acesso
- **Nginx**: Servidor web e proxy reverso

### Infraestrutura Tradicional:
- **Nginx**: Servidor web e proxy reverso
- **MySQL**: Banco de dados
- **Systemd**: Gerenciamento de serviços

## Comandos Úteis

### Desenvolvimento:
```bash
./start.sh                    # Iniciar desenvolvimento
python manage.py runserver    # Servidor Django
python manage.py shell        # Shell Django
python manage.py createsuperuser  # Criar usuário admin
```

### AWS Setup:
```bash
./setup_aws_secrets.sh       # Configurar Secrets Manager
aws secretsmanager get-secret-value --secret-id task-project/prod  # Verificar secret
aws rds describe-db-instances # Listar instâncias RDS
export AWS_REGION=us-east-1 && export AWS_SECRET_NAME=task-project/prod  # Variáveis
```

### Produção:
```bash
sudo -E ./deploy.sh           # Deploy completo (AWS)
sudo ./deploy.sh              # Deploy tradicional
sudo systemctl status task_project    # Status da aplicação
sudo systemctl restart task_project   # Reiniciar aplicação
sudo systemctl status nginx           # Status do Nginx
sudo nginx -t                        # Testar configuração Nginx
```

### Logs:
```bash
sudo journalctl -u task_project -f   # Logs da aplicação
sudo tail -f /var/log/nginx/task_project_access.log  # Logs do Nginx
```

## Licença

Este projeto está sob a licença MIT.
