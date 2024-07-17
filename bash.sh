#!/bin/bash

sudo echo "deb [arch=amd64 trusted=yes] http://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-update/ 1.7_x86-64 non-free contrib main  
deb [arch=amd64 trusted=yes] http://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-base/ 1.7_x86-64 main contrib non-free 
deb [arch=amd64 trusted=yes] http://dl.astralinux.ru/astra/stable/1.7_x86-64/repository-extended/ 1.7_x86-64 non-free contrib main " &> /etc/apt/sources.list.d/sources_last_astra.list

sudo apt install -qy debootstrap
#Сюда установочный диск с астрой не ниже 1.7.2 
sudo echo "#!/bin/bash
debootstrap --include ncurses-term,locales,gawk,lsb-release,acl --components=main,contrib,non-free 1.7_x86-64 \$1 http://repo.inter.sibghk.ru/repo/base_updated_1.7.5" &> ~/makeastra
#debootstrap --include ncurses-term,locales,gawk,lsb-release,acl --components=main,contrib,non-free 1.7_x86-64 \$1 http://dl.astralinux.ru/astra/frozen/1.7_x86-64/1.7.5/repository-main" &> ~/makeastra
sudo chmod +x ~/makeastra

sudo apt install docker.io docker-compose #Установить докер
sudo adduser $USER docker

sudo mkdir ~/docker_image_astra
sudo ~/./makeastra ~/docker_image_astra
sudo cp /etc/apt/sources.list.d/sources_last_astra.list ~/docker_image_astra/etc/apt/sources.list

sudo echo "#!/bin/bash
tar -C \$1 -cpf - . | docker import - \$2 --change \"ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\" --change 'CMD [\"/bin/bash\"]' --change \"ENV LANG=ru_RU.UTF-8\"" &> ~/dockerimport
sudo chmod +x ~/dockerimport
sudo ~/./dockerimport ~/docker_image_astra astra:stable-orel
sudo echo  "<VirtualHost *:80>
    DocumentRoot /srv/www/wordpress
    <Directory /srv/www/wordpress>
        Options FollowSymLinks
        AllowOverride Limit Options FileInfo
        DirectoryIndex index.php
        Require all granted
    </Directory>
    <Directory /srv/www/wordpress/wp-content>
        Options FollowSymLinks
        Require all granted
    </Directory>
</VirtualHost>" &> ~/wordpress.conf

sudo mkdir ~/docker_image_apache
#!TODO добавить сюда скачивание и wordpress и настройку apache
sudo echo "
FROM astra:stable-orel
RUN echo \"ru_RU.UTF-8 UTF-8\" >> /etc/locale.gen | echo \"en_US.UTF-8 UTF-8\" >> /etc/locale.gen | locale-gen | update-locale ru_RU.UTF-8
RUN apt update && apt install -qy apache2 ghostscript libapache2-mod-php php php-bcmath php-curl php-imagick php-intl php-json php-mbstring php-xml php-zip
RUN adduser --disabled-password --gecos \"\" test && echo test:test | chpasswd
RUN mkdir -p /srv/www | chown www-data: /srv/www | curl https://wordpress.org/latest.tar.gz | sudo -u www-data tar zx -C /srv/www
RUN a2ensite wordpress | a2enmod rewrite | a2dissite 000-default
RUN sudo -u www-data sed -i 's/database_name_here/wordpress/' /srv/www/wordpress/wp-config.php
RUN sudo -u www-data sed -i 's/username_here/wordpress/' /srv/www/wordpress/wp-config.php
RUN sudo -u www-data sed -i 's/password_here/12345678/' /srv/www/wordpress/wp-config.php
COPY /root/wordpress.conf /etc/apache2/sites-available/
" &> ~/docker_image_apache/Dockerfile
#RUN mysql -Bse \"CREATE DATABASE wordpress;CREATE USER wordpress@localhost IDENTIFIED BY '12345678';GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,ALTER ON wordpress.* TO wordpress@localhost;FLUSH PRIVILEGES;\"

sudo docker build ~/docker_image_apache -t astra:175-apache

sudo echo  "services:
  apache:
    image: astra:175-apache
    ports:
      - \"8080:80\"
" &> ~/docker-compose.yml
