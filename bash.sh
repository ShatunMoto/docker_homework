#!/bin/bash

echo "deb [arch=amd64 trusted=yes] http://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-update/ 1.7_x86-64 non-free contrib main  
deb [arch=amd64 trusted=yes] http://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-base/ 1.7_x86-64 main contrib non-free 
deb [arch=amd64 trusted=yes] http://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-extended/ 1.7_x86-64 non-free contrib main " &> /etc/apt/sources.list.d/sources_last_astra.list

apt install -qy debootstrap
#Сюда установочный диск с астрой не ниже 1.7.2 
echo "#!/bin/bash
debootstrap --include ncurses-term,locales,gawk,lsb-release,acl --components=main,contrib,non-free 1.7_x86-64 \$1 http://repo.inter.sibghk.ru/repo/base_updated_1.7.5" &> makeastra
#debootstrap --include ncurses-term,locales,gawk,lsb-release,acl --components=main,contrib,non-free 1.7_x86-64 \$1 http://dl.astralinux.ru/astra/frozen/1.7_x86-64/1.7.5/repository-main" &> makeastra
chmod +x makeastra

apt install docker.io docker-compose #Установить докер
adduser $USER docker

mkdir docker_image_astra
./makeastra docker_image_astra
cp /etc/apt/sources.list.d/sources_last_astra.list docker_image_astra/etc/apt/sources.list

echo "#!/bin/bash
tar -C \$1 -cpf - . | docker import - \$2 --change \"ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\" --change 'CMD [\"/bin/bash\"]' --change \"ENV LANG=ru_RU.UTF-8\"" &> dockerimport
chmod +x dockerimport
./dockerimport docker_image_astra astra:stable-orel
mkdir docker_image_apache
#  echo  "<VirtualHost *:80>
#     DocumentRoot /srv/www/wordpress
#     <Directory /srv/www/wordpress>
#         Options FollowSymLinks
#         AllowOverride Limit Options FileInfo
#         DirectoryIndex index.php
#         Require all granted
#     </Directory>
#     <Directory /srv/www/wordpress/wp-content>
#         Options FollowSymLinks
#         Require all granted
#     </Directory>
# </VirtualHost>" &> docker_image_apache/wordpress.conf

#!TODO добавить сюда скачивание и wordpress и настройку apache
echo "
FROM astra:stable-orel
RUN apt update && apt install -qy apache2 default-mysql-client default-mysql-server php8.1 php8.1-mysql libapache2-mod-php8.1 php8.1-cli php8.1-cgi php8.1-gd
RUN a2enmod rewrite
" &> docker_image_apache/Dockerfile
#RUN mysql -Bse \"CREATE DATABASE wordpress;CREATE USER wordpress@localhost IDENTIFIED BY '12345678';GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER ON wordpress.* TO wordpress@localhost;FLUSH PRIVILEGES;\"
# ENV LC_CTYPE=en_US.UTF-8
# ENV LC_ALL=en_US.UTF-8
# ENV LANG=en_US.UTF-8
# ENV LANGUAGE=en:el
# RUN echo \"ru_RU.UTF-8 UTF-8\" >> /etc/locale.gen | echo \"en_US.UTF-8 UTF-8\" >> /etc/locale.gen | locale-gen | update-locale ru_RU.UTF-8

docker build docker_image_apache -t astra:175-apache
mkdir apache_conf data logs
wget -c http://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz -C data/

echo  "services:
  nginx:
    image: astra:175-apache
    volumes:
      - ./apache_conf:/etc/nginx/conf.d
      - ./data:/var/www/html
      - ./logs:/var/log/apache2
      " &> docker-compose.yml
