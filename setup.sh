#!/bin/bash
sudo apt install -y nginx mariadb-server nodejs npm

sudo useradd -m -s /bin/bash teacher
echo "teacher:12345678" | sudo chpasswd
sudo passwd -e teacher

sudo useradd -r -m -s /usr/sbin/nologin mywebapp

sudo useradd -m -s /bin/bash student || true
echo "student:ytrewq" | sudo chpasswd
sudo usermod -aG sudo student

echo "14839938" > /home/student/gradebook

sudo useradd -m -s /bin/bash -g operator operator || true
echo "operator:12345678" | sudo chpasswd
sudo passwd -e operator

sudo bash -c 'cat <<EOF > /etc/sudoers.d/operator
operator ALL=(ALL) NOPASSWD: /usr/bin/systemctl start mywebapp.service
operator ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop mywebapp.service
operator ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart mywebapp.service
operator ALL=(ALL) NOPASSWD: /usr/bin/systemctl status mywebapp.service
operator ALL=(ALL) NOPASSWD: /usr/bin/systemctl reload nginx
EOF'

sudo mariadb -e "CREATE DATABASE IF NOT EXISTS inventory_db;"
sudo mariadb -e "CREATE USER IF NOT EXISTS 'vlad'@'localhost' IDENTIFIED BY 'qwerty';"
sudo mariadb -e "GRANT ALL PRIVILEGES ON inventory_db.* TO 'vlad'@'localhost';"
sudo mariadb -e "FLUSH PRIVILEGES;"

sudo mkdir -p /var/www/mywebapp
sudo rm -rf /var/www/mywebapp/*
sudo cp -r ./* /var/www/mywebapp/

sudo npm install --production --prefix /var/www/mywebapp

cd /var/www/mywebapp && sudo ./node_modules/.bin/prisma generate

sudo chown -R mywebapp:mywebapp /var/www/mywebapp
sudo chmod +x /var/www/mywebapp/migrate.sh

sudo cp /var/www/mywebapp/configs/nginx.conf /etc/nginx/sites-available/mywebapp
sudo ln -sf /etc/nginx/sites-available/mywebapp /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

sudo cp /var/www/mywebapp/configs/mywebapp.socket /etc/systemd/system/
sudo cp /var/www/mywebapp/configs/mywebapp.service /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable --now mywebapp.socket
sudo nginx -t && sudo systemctl restart nginx

sudo passwd -l miracle 

echo "Setup completed successfully!"