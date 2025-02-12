# Imagen base con PHP 8.2-FPM en Alpine
FROM php:8.2-fpm-alpine

# Instalar dependencias necesarias
RUN apk add --no-cache \
    bash \
    git \
    curl \
    zip \
    unzip \
    supervisor \
    nginx \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    oniguruma-dev \
    postgresql-dev \
    icu-dev \
    libxml2-dev \
    mariadb-client \
    gcc \
    g++ \
    make \
    autoconf \
    libzip-dev \
    sqlite-dev

# Instalar extensiones PHP necesarias para Bagisto
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_mysql pdo_pgsql mbstring xml bcmath intl zip exif calendar

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Instalar Node.js y npm
RUN apk add --no-cache nodejs npm

# Establecer directorio de trabajo
WORKDIR /var/www

# Copiar código del proyecto
COPY . .

# Crear enlace simbólico para almacenamiento y asignar permisos
RUN mkdir -p public/storage && ln -sfn /var/www/storage/app/public public/storage \
    && chown -R www-data:www-data storage bootstrap/cache public/storage \
    && chmod -R 777 storage bootstrap/cache public/storage

# Instalar dependencias de PHP y Node.js
RUN composer install --no-dev --optimize-autoloader && npm install && npm run build

# Asegurarse de que existe el archivo .env copiando .env.example si no existe
RUN if [ ! -f .env ]; then cp .env.example .env; fi

# Generar APP_KEY
RUN php artisan key:generate

# Configurar el archivo .env con valores necesarios
RUN echo "APP_INSTALLED=true" >> .env \
    && echo "APP_URL=https://bagisto-ecommerce.onrender.com" >> .env \
    && echo "DB_CONNECTION=mysql" >> .env \
    && echo "DB_HOST=bagisto_mysql" >> .env \
    && echo "DB_PORT=3306" >> .env \
    && echo "DB_DATABASE=bagisto" >> .env \
    && echo "DB_USERNAME=juan" >> .env \
    && echo "APP_ADMIN_URL=admin" >> .env \
    && echo "APP_TIMEZONE=America/Bogota" >> .env \
    && echo "APP_LOCALE=es" >> .env \
    && echo "APP_CURRENCY=COP" >> .env \
    && echo "LOG_CHANNEL=stack" >> .env \
    && echo "RESPONSE_CACHE_ENABLED=true" >> .env \
    && echo "DB_PASSWORD=12345" >> .env

# Limpiar caché y optimizar Laravel
RUN php artisan cache:clear \
    && php artisan config:clear \
    && php artisan route:clear \
    && php artisan view:clear \
    && php artisan optimize

# Copiar configuración de Nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Exponer puerto de Nginx
EXPOSE 8080

# Iniciar servicios: espera 10 segundos para que MySQL esté listo, ejecuta migraciones y arranca PHP-FPM y Nginx.
CMD ["sh", "-c", "sleep 10 && php artisan migrate --force && php artisan cache:clear && php artisan config:clear && php-fpm --nodaemonize & nginx -g 'daemon off;'"]
