FROM php:8.0-cli-alpine
MAINTAINER Backtiste <clavie.b@gmail.com>

RUN apk add --no-cache --virtual .persistent-deps \
        icu-libs \
        zlib 

RUN set -xe \
    && apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        icu-dev \
        zlib-dev \
    && docker-php-ext-install \
        intl \
        zip \
    && docker-php-ext-enable --ini-name 20-intl.ini intl \
    && docker-php-ext-enable --ini-name 05-opcache.ini opcache \
    && apk del .build-deps

# Add source code
WORKDIR /wip

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
COPY .docker/php/php.ini /usr/local/etc/php/conf.d/docker-vars.ini

# https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV PATH="${PATH}:/root/.composer/vendor/bin"

ARG APP_ENV=dev

# Install backend vendors
COPY composer.json composer.lock ./
RUN composer install --prefer-dist --no-dev --no-progress --no-suggest \
    && composer clear-cache

COPY . ./

# tmp configuration ?!
# alpine wtf ?!
RUN chmod -R 1777 /tmp

ENTRYPOINT ["docker-php-entrypoint"]
CMD ["php", "-a"]
