# Imagen para publicar TriviaLive en internet (por ejemplo, en Render).
#
# Adentro corren 4 programas a la vez, cuidados por supervisor:
#   nginx    → recibe TODO por un solo puerto (Render da uno solo)
#   php-fpm  → ejecuta Laravel (la API)
#   reverb   → los WebSockets; nginx le pasa las conexiones de /app/
#   cola     → cierra cada pregunta cuando se acaba el tiempo
FROM php:8.3-fpm-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends nginx supervisor unzip \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-install pcntl opcache

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Primero solo las dependencias: si no cambian, Docker reusa este paso.
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist --no-interaction

COPY . .
RUN composer dump-autoload --optimize --no-dev \
    && mkdir -p storage/framework/cache/data storage/framework/sessions \
       storage/framework/views storage/logs bootstrap/cache

COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/supervisord.conf /etc/supervisor/conf.d/trivia.conf
COPY docker/php-fpm.conf /usr/local/etc/php-fpm.d/zz-trivia.conf
RUN chmod +x docker/arrancar.sh

# Render avisa en qué puerto escuchar con la variable PORT.
ENV PORT=10000
EXPOSE 10000

CMD ["docker/arrancar.sh"]
