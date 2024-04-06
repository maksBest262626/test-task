FROM php:8.2-fpm

ARG USER_ID
ARG GROUP_ID

RUN apt-get update \
    && apt-get install -y apt-utils  \
        libpq-dev libpng-dev  \
        libzip-dev zip unzip  \
        mc \
        ca-certificates \
        libxslt-dev \
        graphviz \
        curl \
        git \
        procps \
        iputils-ping \
        nano \
        rsyslog \
        cron \
        locales \
        netcat-traditional \
        locales-all \
        zlib1g-dev libicu-dev

RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Xdebug
RUN pecl install xdebug
RUN docker-php-ext-enable xdebug

# Redis
RUN pecl install redis
RUN docker-php-ext-enable redis

# Intl for currencies showing
RUN docker-php-ext-configure intl \
&& docker-php-ext-install intl

# Install Postgre PDO, and other libs
RUN docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql
RUN docker-php-ext-install pdo pdo_mysql pdo_pgsql pgsql bcmath gd zip iconv pcntl

# втыкаем русскую локаль и юзера чтобы у www-data были права на запись/создание
# https://stackoverflow.com/questions/28405902/how-to-set-the-locale-inside-a-debian-ubuntu-docker-container
RUN sed -i "s/33:33/$USER_ID:$GROUP_ID/g" /etc/passwd && sed -i "s/33/$GROUP_ID/g" /etc/group \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen \
    && echo "LANG=ru_RU.UTF-8" > /etc/locale.conf \
    && locale-gen \
    && localedef -c -f UTF-8 -i ru_RU ru_RU.UTF-8

RUN mkdir -p /var/log/php/ \
    && mkdir -p /var/log/php/xdebug \
    && mkdir -p /var/log/php/xhprof \
    && mkdir -p /var/log/php/xtrace \
    && touch /var/log/php/xdebug/access.log \
    && chown $USER_ID:$GROUP_ID -R /var/log/php/ \
    && chmod g+rwxs,u+rwx,o+r -R /var/log/php/

ENV LANG ru_RU.UTF-8
ENV LANGUAGE ru_RU:ru
ENV LC_ALL ru_RU.UTF-8

RUN mkdir -p /home/www-data/.composer /home/www-data/.ssh && \
    touch /home/www-data/.ssh/known_hosts && \
    ssh-keyscan -t rsa github.com >> /home/www-data/.ssh/known_hosts && \
    chown -R www-data:www-data /home/www-data && \
    chmod 700 /home/www-data/.ssh && \
    usermod -d /home/www-data www-data

# Install composer
COPY --from=composer:2.5.8 /usr/bin/composer /usr/bin/composer

# Install symfony
RUN curl -sS https://get.symfony.com/cli/installer | bash
RUN mv /root/.symfony5/bin/symfony /usr/local/bin/symfony

WORKDIR /var/www

USER www-data

CMD ["php-fpm"]