#!/bin/bash

# Start mongo.
mongod &
# Start mysql.
mysqld_safe &
# Start apache
/usr/sbin/apache2 -D FOREGROUND
sleep 5
# Start processor.
cd /var/www/ghiro && python manage.py process &