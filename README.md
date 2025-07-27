# Minicurso WTADS 2025.1
Material do Minicurso de Introdução a Computação em Nuvem com a AWS


apt-get install -y pkg-config libmysqlclient-dev

sudo mysql -u root -e "CREATE USER 'taskapp' IDENTIFIED WITH mysql_native_password BY 'task-123'";
sudo mysql -u root -e "GRANT all privileges on *.* to 'taskapp'@'%';"
sudo mysql -u root -e "CREATE DATABASE taskdb;"