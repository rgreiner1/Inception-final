#!/bin/bash

MB_PASSWORD=$(cat /run/secrets/db_password)
MB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
MB_DATABASE="${MYSQL_DATABASE}"  
MB_USER=$(awk -F'[()]' '/^WP_ROOT\(/ {print $2}' /run/secrets/credentials)

if [ ! -d "/run/mysqld" ]; then
    mkdir -p /run/mysqld
    chown -R mysql:mysql /run/mysqld
    chmod 777 /run/mysqld
fi

if [ ! -d "/var/lib/mysql/mysql" ]; then
    mkdir -p /var/lib/mysql
    chown -R mysql:mysql /var/lib/mysql

    mysql_install_db --user=mysql --datadir=/var/lib/mysql --basedir=/usr

    cat << EOF > tmp.sql
USE mysql;
FLUSH PRIVILEGES;

DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

ALTER USER 'root'@'localhost' IDENTIFIED BY '$MB_ROOT_PASSWORD';

CREATE DATABASE IF NOT EXISTS \`$MB_DATABASE\` CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE USER '$MB_USER'@'%' IDENTIFIED BY '$MB_PASSWORD';
GRANT ALL PRIVILEGES ON \`$MB_DATABASE\`.* TO '$MB_USER'@'%';

FLUSH PRIVILEGES;
EOF

    /usr/bin/mysqld --user=mysql --bootstrap < tmp.sql
    rm -f tmp.sql
fi

sed -i "s|skip-networking|# skip-networking|g" /etc/my.cnf.d/mariadb-server.cnf
sed -i "s|.*bind-address\s*=.*|bind-address=0.0.0.0|g" /etc/my.cnf.d/mariadb-server.cnf

echo "done"
exec /usr/bin/mysqld --user=mysql --console
