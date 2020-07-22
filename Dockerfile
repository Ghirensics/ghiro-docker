############################################################
# Ghiro Dockerfile
# https://getghiro.org
############################################################
#
# Copyright (C) 2016 Alessandro Tanasi
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

FROM ubuntu:16.04
LABEL Maintainer="Jonathan Batteas <jonathanbatteas@gmail.com>"
ARG TZ
ENV DEBIAN_FRONTEND noninteractive
ENV TIMEZONE ${TZ}
ENV GHIRO_PASSWORD ghiromanager
ENV GHIRO_USER ghiro
ENV APACHE_RUN_USER  www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR   /var/log/apache2
ENV APACHE_PID_FILE  /var/run/apache2/apache2.pid
ENV APACHE_RUN_DIR   /var/run/apache2
ENV APACHE_LOCK_DIR  /var/lock/apache2
ENV APACHE_LOG_DIR   /var/log/apache2
ENV LOGS /logs
# Copy requirements files.
COPY files/*.txt /tmp/

# Setup basic deps.
RUN apt-get update \
 && xargs apt-get install -y < /tmp/deb-packages.txt \
 && rm /tmp/deb-packages.txt \
 && pip install --upgrade pip \
 && pip install --upgrade -r /tmp/pypi-packages.txt \
 && rm /tmp/pypi-packages.txt \
 && git clone https://github.com/GrahamDumpleton/mod_wsgi.git /mod_wsgi \
 && cd /mod_wsgi && ./configure \
  --with-python=/usr/bin/python \
 && make && make install && make clean \
 && echo 'LoadModule wsgi_module /usr/lib/apache2/modules/mod_wsgi.so' > /etc/apache2/mods-available/wsgi.load \
 && a2enmod wsgi \
 # && echo 'LoadModule wsgi_module modules/mod_wsgi.so' >> /etc/apache2/apache2.conf \
 && echo 'WSGIApplicationGroup %{GLOBAL}' >> /etc/apache2/apache2.conf \
 && echo 'ServerName localhost' >> /etc/apache2/apache2.conf \
 && echo "$TIMEZONE" > /etc/timezone \
 && dpkg-reconfigure -f noninteractive tzdata \
 && export LANGUAGE=en_US.UTF-8 \
 && export LANG=en_US.UTF-8 \
 && export LC_ALL=en_US.UTF-8 \
 && locale-gen en_US.UTF-8 \
 && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales \
 && printf '#!/bin/bash\nxvfb-run --server-args="-screen 0, 1024x768x24" /usr/bin/wkhtmltopdf $*' > /usr/bin/wkhtmltopdf.sh \
 && chmod a+x /usr/bin/wkhtmltopdf.sh \
 && ln -s /usr/bin/wkhtmltopdf.sh /usr/local/bin/wkhtmltopdf \
 && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
 && mkdir -p $LOGS &&  mkdir -p $APACHE_RUN_DIR && mkdir -p $APACHE_LOCK_DIR && mkdir -p $APACHE_LOG_DIR

# Checkout ghiro from git.
RUN git clone https://github.com/Ghirensics/ghiro.git /var/www/ghiro \
	&& pip install -r /var/www/ghiro/requirements.txt

# Configure ghiro.
COPY local_settings.py /var/www/ghiro/ghiro/local_settings.py

RUN mkdir /var/www/ghiro/uploads

VOLUME ["/var/www/ghiro/uploads"]

# Add virtualhost
COPY ./ghiro.conf /etc/apache2/sites-available/ghiro.conf

# Remove default virtualhost.
RUN a2dissite 000-default \
 && a2ensite ghiro \
 && chown -R www-data:www-data /var/www/ghiro/

EXPOSE 80

COPY start.sh /start.sh
RUN chmod 0755 /start.sh
CMD ["bash", "start.sh"]

COPY wait-for-it.sh /wait-for-it.sh
RUN chmod 0755 wait-for-it.sh


COPY install.sh /install.sh
RUN chmod 0755 /install.sh
