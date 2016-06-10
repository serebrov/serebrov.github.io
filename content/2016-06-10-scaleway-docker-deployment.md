---
title: Deploying multiple web applications with Docker on Scaleway
date: 2016-06-10
tags: docker
type: note
---

The purpose of this setup is:

- Setup multiple web apps with different dependencies on the same server
- Link all apps to the same MySQL server
- Manage uploaded files for web apps in the single place (so it is easy to backup them)
- Automatically deploy and update apps on the remote server
- Run the same setup locally, so development environment is very close to production
- Setup backups for MySQL databases and for uploaded files

In this case I deploy to [Scaleway](https://scaleway.com), but same approach can be used for almost any cloud service.
<!-- more -->

## Cloud Server

First, you need the cloud server with one of operation systems, [supported by Docker Machine](https://docs.docker.com/machine/drivers/os-base/) with SSH access.
I used Scaleway's VC1S server with Ubuntu 14.04.
You also need to install [Docker Engine](https://docs.docker.com/engine/installation/linux/ubuntulinux/) and [Docker Machine](https://docs.docker.com/machine/install-machine/) locally.

## Docker Machine - setup Docker remotely

Next step is to setup the Docker on the server, this is done with `docker-machine create` command:

```bash
SSH_HOST=111.222.333.44
SSH_USER=root
SSH_KEY=~/.ssh/id_rsa_scaleway

docker-machine create --driver generic \
 --generic-ip-address $SSH_HOST \
 --generic-ssh-user $SSH_USER \
 --generic-ssh-key $SSH_KEY \
 scaleway
```

Here I use the `generic` docker machine driver, there are also specific drivers for popular cloud providers - [AWS, Digital Ocean, etc](https://docs.docker.com/machine/drivers/).

Check the full setup script [here](files/scaleway-docker/init-docker.sh), on Scaleway I also had to create loopback devices because docker setup failed with `[graphdriver] prior storage driver \"devicemapper\" failed: loopback attach failed`.

If something goes wrong during the setup, run `docker-machine rm scaleway`, fix the problem and run the setup again.

## Deployment setup


This project is responsible for deployment of the web applications to the remote host.

### Projects layout

There are several web applications which I want do deploy, each packaged into the docker container.

On the filesystem they reside in the same `~/web` folder along with the `web-deploy` project which acts as a glue and setups everything together along with MySQL container (used by all projects) and HAProxy (listens to the port 80 and forwards requests to individual containers):

```bash
in ~/web $
projectA/
   Dockerfile
   config/
   db/
   www/
projectB/
   Dockerfile
   config/
   db/
   www/
projectC/
   Dockerfile
   app/
   config/
   db/
   ...
web-deploy/
```

The typical Dockerfile for the php application looks like this:

```
FROM php:5.6-apache

RUN apt-get update && \
  apt-get install -y msmtp wget && \
  apt-get clean

RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng12-dev \
    && docker-php-ext-install -j$(nproc) iconv mcrypt \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd pdo pdo_mysql mysql mysqli

COPY config/msmtprc /etc/msmtprc

RUN echo 'sendmail_path = "/usr/bin/msmtp -t -i"' > /usr/local/etc/php/conf.d/mail.ini
RUN a2enmod expires && a2enmod rewrite

COPY www/ /var/www/html/

VOLUME /var/www/html/files
```

This container is based on the official [php image](https://hub.docker.com/\_/php/).
To make the php `mail` function work, I also setup `msmtp` and configure php to use it.
The example of the msmtp configuration file is [here](files/scaleway-docker/msmtprc).

Here is also an example of the ruby-on-rails application (Redmine) Dockerfile:

```
# re-use image which we already use
FROM php:5.6-apache
MAINTAINER serebrov@gmail.com

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && apt-get install -y ruby libruby \
    libapache2-mod-passenger ruby-dev \
    libmysqlclient-dev libmagickcore-dev libmagickwand-dev \
    build-essential \
    apache2 ruby-passenger \
    && gem install bundler

WORKDIR /var/www/redmine/
COPY ./ /var/www/redmine/
COPY config_prod/*.yml /var/www/redmine/config/

RUN bundle install

COPY config_prod/redmine.conf /etc/apache2/sites-available
RUN chown -R www-data:www-data /var/www/redmine
RUN a2enmod passenger
RUN a2ensite redmine

VOLUME /var/www/redmine/files
```

This container is based on the same base official php container as php applications just to reuse the already downloaded layers.
Ruby application is running under apache with mod passenger.

## The web deploy project

The `web-deploy` project is a glue to build and start the containers for all web projects, link them to mysql if necessary and setup the HAProxy to forward requests to each sub-project.

```bash
in ~/web $
projectA/
projectB/
projectC/
   ...
web-deploy/
  deploy.sh
  init-docker.sh
  init-db-files.sh
  mysql-cli.sh
  utils.sh
  /haproxy
  /mysql
  /build
    projectA.sh
    projectB.sh
    projectC.sh
```

Top level scripts include:

- [web-deploy/deploy.sh](files/scaleway-docker/deploy.sh) - deploy all apps locally or to the remote instance
- [web-deploy/init-docker.sh](files/scaleway-docker/init-docker.sh) - use it for initial server setup (only needed once, for the new server)
- [web-deploy/init-db-files.sh](files/scaleway-docker/init-db-files.sh) - uploads files and database dumps to remote server and then goes over dumps in mysql/dump and drops/creates databases and loads dumps, also users [web-deploy/mysql/init-db.sh](files/scaleway-docker/init-db.sh) and [web-deploy/mysql/dumps/load-dumps.sh](files/scaleway-docker/load-dumps.sh), dump files should be under `web-deploy/mysql/dumps`
- [web-deploy/mysql-cli.sh](files/scaleway-docker/mysql-cli.sh) can be user to start the MySQL client for the MySQL container

The `deploy.sh` script uses docker-machine to build and run the containers on the remote server.
There are several modes it can be used it:
- `./deploy.sh` - deploy (or update) all projects locally
- `./deploy.sh local projectA` - deploy only projectA locally
- `./deploy.sh production` - deploy only projectA on the remote server
- `./deploy.sh production projectA` - deploy only projectA on the remote server

The script looks like this:

```bash
#!/usr/bin/env bash
set -e

SCRIPT_PATH=`dirname $0`
ENVIRONMENT="local"
if [[ "$1" != "" ]]; then
    ENVIRONMENT=$1
else
    echo Environment name is not specified, using 'local'.
fi

if [[ "$2" != "" ]]; then
    # deploy only the specified project
    # for example ./deploy.sh production projecta.com
    # will run ./build/projecta.com
    PROJECTS=$SCRIPT_PATH/build/$2.sh
else
    # deploy all projects
    PROJECTS=$SCRIPT_PATH/build/*.sh
fi

echo "Deploy $PROJECTS"
read -p "Do you want to continue? " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

# add mysql and haproxy, always update them
PROJECTS="$SCRIPT_PATH/mysql/build.sh "$PROJECTS" $SCRIPT_PATH/haproxy/build.sh"

if [[ "$ENVIRONMENT" == "production" ]]; then
  eval "$(docker-machine env scaleway)"
  docker-machine ip scaleway
  set +a
  export | grep DOCKER
fi

for project in $PROJECTS
do
    echo 'Project: ' $project
    $project $ENVIRONMENT
done

if [[ "$ENVIRONMENT" == "production" ]]; then
  set +a
  export | grep DOCKER
fi

docker ps
```

Internally, the `deploy.sh` script goes over the scripts under `/build` sub-folder with build scripts and executes them to create or update docker containers.

The build script looks like this:

```bash
#!/usr/bin/env bash
set -e

SCRIPT_PATH=`dirname $0`
APP_NAME=projectA
CONTAINER_NAME=$APP_NAME-docker
PORT=8091
source $SCRIPT_PATH/../utils.sh
SRC=$SCRIPT_PATH/../../projectA

# if we are running locally, the container will use sources from the host filesystem
# (we create the volume pointing to /html)
# for production, we will copy the sources into the container
ENVIRONMENT="local"
if [[ "$1" != "" ]]; then
    ENVIRONMENT=$1
fi
ENV_DOCKER_OPTS=""
if [[ "$ENVIRONMENT" == "local" ]]; then
  ENV_DOCKER_OPTS="-v $(realpath $SRC)/html:/var/www/html"
fi
echo "Environment: $ENVIRONMENT"

# go to the source folder, where Dockerfile is
cd $SRC
# remove the image if it already exists
docker_rm_app_image $APP_NAME
# rebuild the image
docker build -t $CONTAINER_NAME .
# start the container
docker run -d -p $PORT:80 -v /var/web/projectA/files:/var/www/html/data/upload --name $APP_NAME --link web-mysql:mysql --restart always $ENV_DOCKER_OPTS $CONTAINER_NAME
# initially files belong to the root user of the host OS
# make them available to containter's www-data user
docker exec $APP_NAME sh -c 'chown -R www-data:www-data /var/www/html/files'
```

Few interesting things happen here:

- This project will use port 8091 on the host machine (can be accessed as localhost:8091), this port also will be mentioned in the HAProxy config to redirect requests to this app based on the requested domain name
- For local deployment the container will use source files from the host machine folder, so we can edit them directly without having to login to container, this is very convenient for local development
- The web application files will be stored in the volume, which is available on the host machine at /var/web/projectA/files
- The problem with permissions to the shared volume is solved by running `chown` from within the container (apache runs as www-data and after creation the files folder will belong to root user)
- This build script is used both for local and remote deployment, the remote part is handled by Docker Machine which allows to run docker commands against the remote host (this is handled in the `deploy.sh` script)

Note: the `docker_rm_app_image` function from the build script is defined in the [utils.sh script](files/scaleway-docker/utils.sh).

The `web-deploy` project also includes setup for HAProxy and MySQL containers.

## HAProxy setup

This container (resides in the web-deploy/haproxy) runs HAProxy and it serves as main entry point. Requests to port 80 are reverse-proxied to other containers.
The Dockerfile is simple:

```
FROM haproxy:1.5
COPY ./haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
# this is needed to setup ssl for one of projects
COPY ./mycompany.pem /etc/ssl/certs/
```

The configuration file looks like this:

```
global
    log /dev/log local2
    maxconn     2048
    tune.ssl.default-dh-param 2048
    #debug

defaults
    log     global
    option  dontlognull
    mode http
    option forwardfor
    option http-server-close
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000s
    stats enable
    stats auth haadimn:ZyXuuXYZ
    stats uri /haproxyStats

frontend http-in
    bind *:80

    # Define hosts based on domain names
    acl host_projecta hdr(host) -i projecta.com
    acl host_projecta hdr(host) -i www.projecta.com
    # this name is used for local testing
    acl host_projecta hdr(host) -i www.projecta.local
    acl host_projectb hdr(host) -i projectb.com
    acl host_projectb hdr(host) -i www.projectb.com
    # handle sub-domains (use hdr_end here, not hdr)
    acl host_projectc hdr_end(host) -i projectc.com

    # redirect projectd to https
    redirect scheme https if host_projectd !{ ssl_fc }

    ## figure out backend to use based on domainname
    use_backend projecta if host_projecta
    use_backend projectb if host_projectb
    use_backend projectc if host_projectc

frontend https-in
    bind *:443 ssl crt /etc/ssl/certs/mycompany.pem

    # Define hosts based on domain names
    acl host_projectd hdr(host) -i projectd.com

    use_backend projectd if host_projectd

backend projecta
    balance roundrobin
    server srv_pawnshop-soft-ru 127.0.0.1:8091

backend projectb
    balance roundrobin
    server srv_pawnshop-soft-kz 127.0.0.1:8092

backend projectc
    balance roundrobin
    server srv_lombard 127.0.0.1:8093

backend projectd
    balance roundrobin
    server srv_redmine 127.0.0.1:8100
```

The build script is:

```bash
#!/usr/bin/env bash

export | grep DOCKER
docker-machine ip scaleway

SCRIPT_PATH=`dirname $0`
APP_NAME=web-haproxy
CONTAINER_NAME=web-haproxy-docker
source $SCRIPT_PATH/../utils.sh

pushd $SCRIPT_PATH
docker_rm_app_image $APP_NAME
docker build -t $CONTAINER_NAME .
docker run -d --restart always --net=host -p 80:80 -p 443:443 -v /dev/log:/dev/log --name $APP_NAME $CONTAINER_NAME
popd

```

The HAProxy container is launched with `--net=host` option, so it can directly access all the ports exposed by other containers.

Some hints to to debug problems with HAProxy setup:

- Uncomment 'debug' in the config file
- Check 'docker logs web-haproxy'
- Check system log (/var/log/syslog), with the configuration above the HAProxy container will log to host's system log (see https://github.com/dockerfile/haproxy/issues/3)

The HAProxy also handles SSL (HTTPS) connections. For one of projects it redirects http to https.
See the config file and [this post](https://www.digitalocean.com/community/tutorials/how-to-implement-ssl-termination-with-haproxy-on-ubuntu-14-04) for more information.

The HAProxy stats are available via http: hostname.com/haproxyStats. Login and password are in the config file.

## MySql setup

The MySql container (it is under web-deploy/mysql folder) also has a simple Dockerfile:

```
FROM mysql:5.6
ENV MYSQL_ROOT_PASSWORD=myrootpassword

VOLUME /var/www/mysql
```

The build script looks like this:

```bash
#!/usr/bin/env bash

SCRIPT_PATH=`dirname $0`
APP_NAME=web-mysql
CONTAINER_NAME=$APP_NAME-docker
source $SCRIPT_PATH/../utils.sh

pushd $SCRIPT_PATH
docker_rm_app_image $APP_NAME
docker build -t $CONTAINER_NAME .

docker run -d -v /var/web/mysql-data:/var/lib/mysql --restart always --name $APP_NAME $CONTAINER_NAME
popd
```

The data folder is mapped to the host machine to /var/web/mysql-data.
The app containers which need the database are linked to this container.

## Docker on the server

Some useful commands to view and manage Docker containers:

* Information about docker `docker info`
* List running containers: `docker ps`
* Information about specific container `docker inspect {appname}`
* View application logs `docker logs {appname}`
* Restart application `docker restart {appname}`
* Run shell inside the container: `docker exec -it {appname} bash  # replace {appname} with name from docker ps`
* Run the command inside the container (in this case - backup mysql databases): `docker exec web-mysql sh -c 'exec mysqldump --all-databases -uroot -p"$MYSQL_ROOT_PASSWORD"' | gzip -9 > all-databases.sql.gz`

## Cron in Docker and Backups on Scaleway

There are few options to run cron with docker:
* Run cron on the host machine (cronjobs can interact with containers via `docker exec ...`)
* Run separate container with cron (cronjobs can interact with other containers via network or shared volumes)
* Run multiple processes inside application containers (application and cron) usind supervisor or runit, for example, see http://phusion.github.io/baseimage-docker/.
* Run multiple processes via `CMD` instruction in the Dockerfile (for example, see http://programster.blogspot.com/2014/01/docker-working-with-cronjobs.html)

Here I chose the first option to use host machine cron. First, the host machine is Ubuntu 14.04, so it already has cron. Second, everything runs on the same machine and I have no plans to scale out this setup, so it was the easiest option.

The [web-deploy/init-db-files.sh](files/scaleway-docker/init-db-files.sh) script contains code to setup cron, here is the related part:

```bash
  docker-machine ssh scaleway apt-get install -y postfix mutt s3cmd
  docker-machine scp -r ./config/web-cron scaleway:/etc/cron.d/
  docker-machine scp -r ./config/.s3cfg scaleway:/root
```

The `postfix` and `mutt` are need for cron to send local emails about jobs. You can check these mails by ssh'ing to the server and running mutt.
The `s3cmd` is used to backup databases and files from the shared storage to S3.
The `.s3cfg` contains credentials for [s3cmd](http://s3tools.org/s3cmd), it can be generated by running `s3cmd --configure`.

Backups are very important, because at the moment Scaleway does not provide highly reliable hardware (no RAID disks, see [this thread](https://community.scaleway.com/t/i-have-questions-about-scaleway/891/2)).
And to [make a snapshot](https://www.scaleway.com/docs/backup-your-data-with-snapshots/), you need to archive the instance (it takes few minutes), make the snapshot and launch the instance again, so there is a noticeable down-time period.
So I used cront to backup files and databases to Amazon's S3.

Note: Scaleway has compatible to S3 storage, called [SIS](https://www.scaleway.com/features/sis/), but at the moment it is not available (at least in my account).
When I try to create bucket from the command line it returns `S3 error: 400 (TooManyBuckets): You have attempted to create more buckets than allowed`.
And the note in the Scaleway UI states "We're currently scaling up our SIS infrastructure to handle the load generated by all our new users. All new bucket creation are currently forbidden to preserve the service quality for current SIS users.".

The cron file to perform backups looks this way:

```
# In the case of problems, cron sends local email, can be checked with mutt
# (it requires apt-get install postfix mutt)
# Also check cron messages in /var/log/syslog
# update geolite database
# Note: docker exec should not have -t (tty) option, there is no tty, -i is also not needed
0 1 * * Sun root docker exec projecta /var/www/service/cron-update-geoip-db.sh
# backup all databases to s3
0 5 * * *   root docker exec web-mysql sh -c 'exec mysqldump --all-databases -uroot -p"$MYSQL_ROOT_PASSWORD"' | gzip -9 > all-databases.sql.gz && s3cmd put all-databases.sql.gz s3://myweb-backup/$(date +\%Y-\%m-\%d-\%H-\%M-\%S)-all-databases.sql.gz && rm all-databases.sql.gz
0 6 * * *   root s3cmd sync /var/web s3://myweb-backup/storage/
```

The command to backup mysql databases does few things:

* Run `mysqldump` inside the MySQL container via `docker exec`
* Pipe the result to `gzip` to archive it
* Put the archive to S3, add a timestamp to the file name

And since all application containers map their files folders under host's `/var/web`, I simply sync this folder to my S3 bucket.

## Conclusion

As we can see, Docker can be successfully used not only to isolate application dependencies, but, thanks to Docker Machine, also to deploy and update applications on the remote server.
Using the approach above, it is possible also provide both ease of development (in local environment source files are mapped from the host machine and can be edited outside of the container) and avoid using private images (for production source files are copied into the container).

This post turned to be quite long and there is a lot of source code, both for shell scripts and configs.
I am thinking on putting the whole thing to github as a sample setup project, please let me know in comments if that would be useful.

<div class="popup">
    <div class="close">close</div>
    <div class="download"><a href="">Download (<span class="name"></span>)</a></div>
    <div class="popup-content"></div>
</div>

<style type="text/css">
</style>
<script type="text/javascript">
$(document).ready(function() {
    var popup = {
      _$link: null,

      show: function($link) {
        if (this._$link) {
          this.hide();
        }
        this._$link = $link;
        this._$link.addClass("selected");
        var self = this;
        $.get(this._$link.attr('href'), function(data) {
            $(".popup-content").html(data);
            $(".popup .download a").attr('href', self._$link.attr('href'));
            $(".popup .download a span.name").html(
                self._$link.attr('href').split('/').pop()
            );
            $(".popup").slideFadeToggle(function() {
                //can do something here
            });
        });
      },

      hide: function() {
        if (!this._$link) {
          return;
        }
        var self = this;
        $('.popup').slideFadeToggle(function() {
          self._$link.removeClass('selected');
          self._$link = null;
        });
      }
    };

    $.fn.slideFadeToggle = function(easing, callback) {
      return this.animate({ opacity: 'toggle', height: 'toggle' }, 'fast', easing, callback);
    };

    $('.close').on('click', function(e) {
      popup.hide();
      e.stopPropagation();
    });
    $('body').on('click', function(e) {
      if ($(e.target).parents('.popup').length > 0) {
        return;
      }
      popup.hide();
    });

    function isSelectable(link) {
        var href = $(link).attr('href');
        if (href && href.endsWith("config")) {
            return true;
        }
        return false;
    }
    $("a").each(function(idx, link) {
        if (isSelectable(link)) {
          $(link).addClass('selectable');
        }
    });
    $("a").click(function(event) {
        var elem = $(event.target);
        if (!isSelectable(elem)) {
            return true;
        }
        if ($(this).hasClass("selected")) {
            popup.hide();
        } else {
            popup.show($(this));
        }
        return false;
    });
});
</script>
