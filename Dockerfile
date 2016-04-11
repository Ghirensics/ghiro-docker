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

FROM       ubuntu:16.04
MAINTAINER Alessandro Tanasi <alessandro@tanasi.it>

ENV DEBIAN_FRONTEND noninteractive
ENV TIMEZONE Europe/Rome
ENV GHIRO_PASSWORD ghiromanager
ENV GHIRO_USER ghiro

# Copy requirements files.
COPY files/*.txt /tmp/

# Update repositories.
RUN apt-get update

# Setup basic deps.
RUN apt-get update
RUN xargs apt-get install -y < /tmp/deb-packages.txt
RUN rm /tmp/deb-packages.txt
RUN pip install --upgrade -r /tmp/pypi-packages.txt
RUN rm /tmp/pypi-packages.txt

# Configure timezone and locale
RUN echo "$TIMEZONE" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata
RUN export LANGUAGE=en_US.UTF-8 && \
    export LANG=en_US.UTF-8 && \
    export LC_ALL=en_US.UTF-8 && \
    locale-gen en_US.UTF-8 && \
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales

# Configure wkhtmltopdf
RUN printf '#!/bin/bash\nxvfb-run --server-args="-screen 0, 1024x768x24" /usr/bin/wkhtmltopdf $*' > /usr/bin/wkhtmltopdf.sh
RUN chmod a+x /usr/bin/wkhtmltopdf.sh
RUN ln -s /usr/bin/wkhtmltopdf.sh /usr/local/bin/wkhtmltopdf

# Checkout ghiro from git.
RUN git clone https://github.com/Ghirensics/ghiro.git /var/www/ghiro

# Setup python requirements using pypi.
RUN pip install -r /var/www/ghiro/requirements.txt

# Configure ghiro.
ADD local_settings.py /var/www/ghiro/ghiro/local_settings.py

# Ghiro setup.
RUN cd /var/www/ghiro && python manage.py syncdb --noinput

# Create super user.
RUN cd /var/www/ghiro && echo "from users.models import Profile; Profile.objects.create_superuser('$GHIRO_USER', 'yourmail@example.com', '$GHIRO_PASSWORD')" | python manage.py shell

# Add virtualhost
ADD ./ghiro.conf /etc/apache2/sites-available/

# Remove default virtualhost.
RUN a2dissite 000-default

# Enable ghiro virtualhost.
RUN a2ensite ghiro

# Clean-up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE     80

ADD start.sh /start.sh
RUN chmod 0755 /start.sh
CMD ["bash", "start.sh"]
