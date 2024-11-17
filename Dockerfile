# Use PHP with Apache as the base image
FROM php:7.4-apache as us_web

ARG WWWGROUP

# Set the working directory
WORKDIR /var/www/html

# Install Additional System Dependencies
RUN apt-get update -y && apt-get install -y git \
	sendmail \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
	libzip-dev	\
    unzip \
    supervisor \
    nginx \
    build-essential \
    openssl \
    vim \
    wget \
    subversion

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Enable Apache mod_rewrite for URL rewriting
RUN a2enmod rewrite

# Install PHP extensions
# RUN docker-php-ext-configure zip --with-libzip # Valid only until PHP 7.3
RUN docker-php-ext-configure zip
RUN docker-php-ext-install zip
RUN docker-php-ext-install pdo mbstring gd pdo_mysql sockets

# Configure Apache DocumentRoot to point to Laravel's public directory
# and update Apache configuration files
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Copy the application code
COPY . /var/www/html

# Set the working directory
WORKDIR /var/www/html

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN git config --global --add safe.directory /var/www/html
#RUN sudo chown -R _currentuser_:www-data /var/www/html && chmod -R g+sw /var/www/html

# Install project dependencies
RUN composer install

# Set permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
RUN chown -R www-data:www-data /var/www/html

# Install security keys
RUN php artisan key:generate

# give permission to storage directory
RUN chmod -R 775 storage/

#Link storage folder to public folder
RUN php artisan storage:link

# Clear cache
RUN php artisan cache:clear
RUN php artisan config:clear
RUN php artisan view:clear
