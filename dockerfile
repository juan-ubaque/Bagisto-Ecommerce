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
    sqlite-dev # ✅ Soluciona el problema de SQLite3 en Node.js

# Instalar extensiones PHP necesarias para Bagisto
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_mysql pdo_pgsql mbstring xml bcmath intl zip exif calendar

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# ✅ Instalación correcta de Node.js desde Alpine
RUN apk add --no-cache nodejs npm

# Establecer directorio de trabajo
WORKDIR /var/www

# Copiar código del proyecto antes de instalar dependencias
COPY . .

# Asignar permisos correctos
RUN chmod -R 775 storage bootstrap/cache

# Instalar dependencias de PHP y Node.js
RUN composer install --no-dev --optimize-autoloader && npm install && npm run build

# Copiar configuración de Nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Exponer puerto de Nginx
EXPOSE 8080

# Iniciar servicios (Nginx + PHP-FPM)
CMD ["sh", "-c", "php-fpm -D && nginx -g 'daemon off;'"]
