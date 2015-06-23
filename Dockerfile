# Dockerizing MongoDB: Dockerfile for building MongoDB images
# Based on ubuntu:latest, installs MongoDB following the instructions from:
# http://docs.mongodb.org/manual/tutorial/install-mongodb-on-ubuntu/

FROM       ubuntu:latest
MAINTAINER Alessandro Tanasi <alessandro@tanasi.it>

# Update repositories.
RUN DEBIAN_FRONTEND=noninteractive apt-get update

# Install software
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y git locales

# Configure timezone and locale
RUN echo "Europe/Rome" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata
RUN export LANGUAGE=en_US.UTF-8 && \
    export LANG=en_US.UTF-8 && \
    export LC_ALL=en_US.UTF-8 && \
    locale-gen en_US.UTF-8 && \
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales

# Setup python stuff.
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y python-pip build-essential python-dev python-gi
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libgexiv2-2 gir1.2-gexiv2-0.10
# Pillow
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libtiff4-dev libjpeg8-dev zlib1g-dev libfreetype6-dev liblcms2-dev libwebp-dev tcl8.5-dev tk8.5-dev python-tk

# Install Apache.
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 libapache2-mod-wsgi

# Install and configure wkhtmltopdf
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y wkhtmltopdf xvfb
RUN printf '#!/bin/bash\nxvfb-run --server-args="-screen 0, 1024x768x24" /usr/bin/wkhtmltopdf $*' > /usr/bin/wkhtmltopdf.sh
RUN chmod a+x /usr/bin/wkhtmltopdf.sh
RUN ln -s /usr/bin/wkhtmltopdf.sh /usr/local/bin/wkhtmltopdf

# Install MongoDB.
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
RUN echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.0.list
RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y mongodb-org

# Install mysql.
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server
RUN { echo mysql-server mysql-server/root_password password ghiromanager ''; \
      echo mysql-server mysql-server/root_password_again password ghiromanager ''; \
    } | debconf-set-selections
RUN mysqladmin --defaults-extra-file=/etc/mysql/debian.cnf create ghiro

# Checkout ghiro from git.
RUN git clone https://github.com/Ghirensics/ghiro.git /var/www/ghiro

# Setup python requirements using pypi.
RUN pip install -r /var/www/ghiro/requirements.txt

# Additional Mysql driver.
RUN DEBIAN_FRONTEND=noninteractive apt-get install libmysqlclient-dev
RUN pip install MySQL-python

# Configure ghiro.
ADD local_settings.py /var/www/ghiro/ghiro/local_settings.py

# Ghiro setup.
RUN cd /var/www/ghiro && python manage.py syncdb --noinput

# Create super user.
RUN cd /var/www/ghiro && echo "from users.models import Profile; Profile.objects.create_superuser('ghiro', 'yourmail@example.com', 'ghiromanager')" | python manage.py shell

# Add virtualhost
ADD ./ghiro.conf /etc/apache2/sites-available/

# Remove default virtualhost.
RUN a2dissite 000-default

# Enable ghiro virtualhost.
RUN a2ensite ghiro

# Clean-up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE     80

VOLUME ["/var/lib/mongodb"]
VOLUME ["/var/lib/mysql"]

ADD start.sh /start.sh
RUN chmod 0755 /start.sh
CMD ["bash", "start.sh"]