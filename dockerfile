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

# Instalación de Node.js desde Alpine
RUN apk add --no-cache nodejs npm

# Establecer directorio de trabajo
WORKDIR /var/www

# Copiar código del proyecto antes de instalar dependencias
COPY . .

# Asegurar que `public/storage` existe
RUN mkdir -p public/storage && ln -sfn /var/www/storage/app/public public/storage

# Asignar permisos correctos al usuario www-data
RUN chown -R www-data:www-data storage bootstrap/cache public/storage \
    && chmod -R 777 storage bootstrap/cache public/storage

# Instalar dependencias de PHP y Node.js
RUN composer install --no-dev --optimize-autoloader && npm install && npm run build

# Generar APP_KEY antes del despliegue
RUN php artisan key:generate

# Configurar la conexión a la base de datos en el `.env`
RUN echo "APP_INSTALLED=true" >> .env \
    && echo "APP_URL=https://bagisto-ecommerce.onrender.com" >> .env \
    && echo "DB_CONNECTION=mysql" >> .env \
    && echo "DB_HOST=becm51vqfpialbthq6vw-mysql.services.clever-cloud.com" >> .env \
    && echo "DB_PORT=3306" >> .env \
    && echo "DB_DATABASE=becm51vqfpialbthq6vw" >> .env \
    && echo "DB_USERNAME=uawz1jgviwol8u3v" >> .env \
    && echo "DB_PASSWORD=a5qBrWELqVwko8CQezSp" >> .env

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

# Iniciar servicios con delay para esperar MySQL
CMD ["sh", "-c", "sleep 10 && php artisan migrate --force && php artisan cache:clear && php artisan config:clear && php-fpm --nodaemonize & nginx -g 'daemon off;'"]
