#!/bin/bash

MYSQL_USER=$(awk -F'[()]' '/^WP_ROOT\(/ {print $2}' /run/secrets/credentials)
WORDPRESS_ADMIN_USER=$(awk -F'[()]' '/^WP_ROOT\(/ {print $2}' /run/secrets/credentials)
WORDPRESS_ROOT_PASSWORD=$(awk -F'[()]' '/^WP_ROOT_PASS\(/ {print $2}' /run/secrets/credentials)
WORDPRESS_ADMIN_EMAIL=$(awk -F'[()]' '/^WP_ROOT_EMAIL\(/ {print $2}' /run/secrets/credentials)
WORDPRESS_USER=$(awk -F'[()]' '/^WP_USER\(/ {print $2}' /run/secrets/credentials)
WORDPRESS_USER_PASS=$(awk -F'[()]' '/^WP_USER_PASS\(/ {print $2}' /run/secrets/credentials)
WORDPRESS_EMAIL=$(awk -F'[()]' '/^WP_USER_EMAIL\(/ {print $2}' /run/secrets/credentials)

echo "Waiting for MariaDB to be ready..."
sleep 5

echo "Setting up WordPress..."

if [ ! -d "/var/www/html/wp-includes" ]; then
    echo "Downloading WordPress core..."
    if ! wp core download --path="/var/www/html"; then
        echo "Failed to download WordPress"
        ls -l /var/www/html
        exit 1
    fi
else
    echo "WordPress core already downloaded."
fi

if [ ! -f "/var/www/html/wp-config.php" ]; then
    echo "Creating wp-config.php..."
    if ! wp config create --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="$(cat /run/secrets/db_password)" \
        --dbhost="${MYSQL_HOSTNAME}" \
        --path="/var/www/html"; then
        echo "Failed to create wp-config.php"
        exit 1
    fi
else
    echo "wp-config.php already exists."
fi

if ! wp core is-installed --path="/var/www/html"; then
    echo "Installing WordPress..."
    if ! wp core install --url="${WORDPRESS_HOST}" \
        --title="Inception" \
        --admin_user="${WORDPRESS_ADMIN_USER}" \
        --admin_password="${WORDPRESS_ROOT_PASSWORD}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
        --path="/var/www/html"; then
        echo "Failed to install WordPress"
        exit 1
    fi
else
    echo "WordPress is already installed."

fi

wp user create ${WORDPRESS_USER} ${WORDPRESS_EMAIL} \
    --role=author \
    --user_pass=$WORDPRESS_USER_PASS \
    --porcelain

echo "WordPress setup complete."

exec php-fpm83 -F