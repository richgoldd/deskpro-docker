FROM php:7-apache

RUN set -x \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		cron \
		libc-client-dev \
		libfreetype6-dev \
		libicu-dev \
		libjpeg62-turbo-dev \
		libkrb5-dev \
		libldap2-dev \
		libmcrypt-dev \
		libpng12-dev \
		libxml2-dev \
		libzip-dev \
		mariadb-client \
		unzip \
	&& docker-php-ext-install -j$(nproc) \
		iconv \
		intl \
		mcrypt \
		opcache \
		pdo_mysql \
		soap \
		zip \
	&& docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
	&& docker-php-ext-install -j$(nproc) gd \
	&& docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
	&& docker-php-ext-install -j$(nproc) imap \
	&& docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
	&& docker-php-ext-install -j$(nproc) ldap \
	&& a2enmod \
		rewrite \
	&& apt-get remove -y \
		libc-client-dev \
		libfreetype6-dev \
		libicu-dev \
		libjpeg62-turbo-dev \
		libkrb5-dev \
		libldap2-dev \
		libmcrypt-dev \
		libpng12-dev \
		libxml2-dev \
		libzip-dev \
	&& rm -rf /var/lib/apt/lists/*

RUN curl -L https://www.deskpro.com/downloads/deskpro.zip -o /usr/src/deskpro.zip

ENV GOSU_VERSION 1.10
RUN set -x \
    && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && curl -L -o /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
    && curl -L -o /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

VOLUME /var/www/html

RUN rm -rf /etc/apache2/sites-enabled/000-default.conf

COPY deskpro.conf /etc/apache2/sites-enabled/deskpro.conf

COPY php.ini /usr/local/etc/php/

COPY deskpro-docker-* /usr/local/bin/

ENTRYPOINT ["deskpro-docker-entrypoint"]
CMD ["deskpro-docker-cmd"]
