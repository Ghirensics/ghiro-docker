To install Ghiro using Docker, from the root of this project run

```
docker-compose -f docker-compose.yml -f docker-compose-install.yml up -d
```

This will perform the migrations, and functions that must be run only once.

To use Ghiro after the installation run:

```
docker-compose up -d
```

Ghiro will then be available in your browser at [http://localhost:9991/](http://localhost:9991/)

Default username: **ghiro**

Default password: **ghiromanager**

To upload images, place the images you want to import into the `images/` folder. In the interface, add folder `uploads/{your folder}`. To begin processing your images, `docker exec --rm -it {container_name} /usr/bin/python /var/www/ghiro/manage.py process`