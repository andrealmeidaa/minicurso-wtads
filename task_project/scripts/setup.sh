#!/bin/bash -xe
apt update -y
apt install nodejs unzip wget pkg-config  git mysql-server libmysqlclient-dev -y
cd /home/ubuntu
git clone https://github.com/andrealmeidaa/minicurso-wtads.git
cd minicurso-wtads/task_project
pip install -r requirements.txt

mysql -u root -e "CREATE USER 'taskapp' IDENTIFIED WITH mysql_native_password BY 'task-123'";;
mysql -u root -e "GRANT all privileges on *.* to 'taskapp'@'%';"
mysql -u root -e "CREATE DATABASE taskdb;"
sed -i 's/.*bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl enable mysql
service mysql restart
export DB_HOST=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
export DB_USER=taskapp
export DB_PASSWORD=task-123
export DB_NAME=taskdb
export APP_PORT=8000
npm start &
echo '#!/bin/bash -xe
cd /home/ubuntu/resources/codebase_partner
export APP_PORT=80
npm start' > /etc/rc.local
chmod +x /etc/rc.local