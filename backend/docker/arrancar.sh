#!/bin/sh
# Lo que pasa cada vez que el servidor arranca.
set -e
cd /var/www/html

# La base de datos es un archivo SQLite dentro del contenedor. En el plan
# gratis de Render se borra cuando el servicio se duerme o se reinicia:
# por eso la creamos y cargamos las preguntas en cada arranque.
[ -f .env ] || cp .env.example .env
touch database/database.sqlite

# La clave que usa Laravel para cifrar. Si no la configuraste, se inventa una.
if [ -z "$APP_KEY" ]; then
    APP_KEY="base64:$(head -c 32 /dev/urandom | base64)"
    export APP_KEY
fi

php artisan migrate --force --seed
php artisan optimize
chown -R www-data:www-data storage bootstrap/cache database

sed -i "s/PUERTO/${PORT:-10000}/" /etc/nginx/nginx.conf
exec supervisord -n -c /etc/supervisor/supervisord.conf
