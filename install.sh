#!/bin/bash

python /var/www/ghiro/manage.py makemigrations && python /var/www/ghiro/manage.py migrate --noinput
echo "from users.models import Profile; Profile.objects.create_superuser('$GHIRO_USER', 'yourmail@example.com', '$GHIRO_PASSWORD')" | python /var/www/ghiro/manage.py shell
echo "ghiro has been installed."
