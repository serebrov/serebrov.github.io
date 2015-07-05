---
title: How to set up Drone CI on EC2 instance via Elastic Beanstalk
date: 2015-07-05
tags: aws,eb,drone
---

[Drone CI](https://github.com/drone/drone) uses [Docker](https://www.docker.com/) containers to run tests for your application hosted on [github](http://github.com).

It not complex to set up the automatic testing for your application and run Drone CI on EC2 instance using Elastic Beanstalk. It is even not necessary to have a dedicated EC2 instance for CI system, for example, I run it on the staging server.
<!-- more -->

# Drone CI setup
First you'll need to create a drone configuration file, `.drone.yml`, which looks like this:

```yaml
image: serebrov/centos-python2.7-java
env:
  - GOPATH=/var/cache/drone
script:
  - pip install -r requirements.txt
  - ./scripts/ci_test.sh
notify:
  email:
    recipients:
      - mymail@gmail.com
```

As you can see the setup is really simple. I have a [custom docker image](https://github.com/serebrov/centos-python2.7-java) which installs all the application requirements.
Then drone runs `pip install -r requirements.txt` to python app dependencies and runs `ci_test.sh` shell script to launch testing.
This script looks like this:

```bash
#!/bin/bash
# set -e

SCRIPT_PATH=`dirname $0`
PYTHON=python
if which python27; then
    PYTHON=python27
fi

cd $SCRIPT_PATH/..

$PYTHON -m unittest discover -s tests
RESULT_MOCK=$?
pushd $SCRIPT_PATH/../tests/dynamodb-local
  java -Djava.library.path=./DynamoDBLocal_lib -jar ./DynamoDBLocal.jar -inMemory -sharedDb &
  PID=$!
popd
echo "Started local dynamodb: $PID"
USE_MOCK= $PYTHON -m unittest discover -s tests
RESULT_LOCALDB=$?
kill -9 $PID
exit $(($RESULT_MOCK+$RESULT_LOCALDB))
```

My application uses Amazon DynamoDB, and I run tests twice - first using a simple in-memory DynamoDB mock and one more time using [local DynamoDB](https://aws.amazon.com/blogs/aws/dynamodb-local-for-desktop-development/).

Mock is used during development and tests run very fast (few seconds) and local DynamoDB is much slower and we need few minutes to run tests, but we can catch some specific errors related to the database usage.

# Elastic Beanstalk setup

Elastic Beanstalk setup allows to automatically install Drone CI when new EC2 instance is launched.

Here it is good to have a single-instance Elastic Beanstalk environment and scripts below will install Drone on the EC instance.

First, the EB config (`.ebextensions/app.config`):

```yaml
container_commands:
  004-start-container-commands:
    command: logger "Start deploy script" -t "DEPLOY"
  005-command:
    command: chmod +x .ebextensions/deploy.sh
  006-deploy:
    command: .ebextensions/deploy.sh 2>&1 | /usr/bin/logger -t "DEPLOY" ; test ${PIPESTATUS[0]} -eq 0
  010-start-container-commands:
    command: logger "Start container commands" -t "DEPLOY"
  190-clearcaches:
    command: (echo 'flush_all' | nc localhost 11211) 2>&1 |/usr/bin/logger -t "DEPLOY"
  200-end-container-commands:
    command: logger "End container commands" -t "DEPLOY"

packages:
  yum:
    gcc: []
    gcc-c++: []
    docker: []
    python-devel: []
    atlas-sse3-devel: []
    lapack-devel: []

services:
  sysvinit:
    docker:
      enabled: true
      ensureRunning: true

```

It will install packages I need (including docker) and run the `deploy.sh` script which does the Drone installation:

```shell
#!/usr/bin/env bash
set -e

SCRIPT_PATH=`dirname $0`

if [[ $APP_ENV != "staging" ]]; then
  echo 'Not a staging env, exit without installation'
  exit 0
fi
copy_ext $SCRIPT_PATH/files/droned.conf /etc/init/droned.conf 0755 root root
echo "Start drone check/install"
if which /usr/local/bin/drone; then
    echo "Found drone, skip install"
    copy_ext $SCRIPT_PATH/files/drone.toml /etc/drone/drone.toml 0755 root root
    if (stop droned); then
      echo 'Stopped drone'
    fi
    start droned
else
    echo "Installing drone"
    wget downloads.drone.io/master/drone.rpm
    yum -y -q install drone.rpm
    # Create a user and group 'droned', -M == no home dir
    # Note: better to use separate user, but there was a permission error:
    #   Post http:///var/run/docker.sock/v1.9/build?q=1&rm=1&t=drone-4dcf1ea3fb: dial unix /var/run/docker.sock: permission denied
    # so for now use sudo, would be good to use droned user (see upstart script)
    # probably this should help: https://docs.docker.com/installation/ubuntulinux/#create-a-docker-group
    adduser -M --user-group droned
    passwd -l droned
    chown -R droned:droned /var/lib/drone
    # # to prevent 'sudo: sorry, you must have a tty to run sudo'
    sed -ie 's/Defaults.*requiretty.*/# Defaults requiretyy/gI' /etc/sudoers
    copy_ext $SCRIPT_PATH/files/drone.toml /etc/drone/drone.toml 0755 root root
    start droned
fi

```

This script uses `utils.sh`, you can find it [here](/html/2015-04-02-elastic-beanstalk-python.html).

There are two more configuration files used in the setup process.

First is `droned.conf`, an upstart script.

You may not need it if your system has systemd, but Amazon Linux I used on my instance didn't have it and Drone raised this error:

```text
which: no systemctl in (/sbin:/bin:/usr/sbin:/usr/bin:/usr/X11R6/bin)
Apr 14 11:55:44 ip-172-31-1-79 DEPLOY: Couldn't find systemd to control Drone, cannot proceed.
Apr 14 11:55:44 ip-172-31-1-79 DEPLOY: Open an issue and tell us about your system.
added init script
```

So I added a custom upstart script to fix this:

```shell
#!upstart
description "Droned upstart job"

start on startup
stop on shutdown

script
    # custom http server settings
    # export DRONE_SERVER_PORT=""
    # export DRONE_SERVER_SSL_KEY=""
    # export DRONE_SERVER_SSL_CERT=""

    # session settings
    # export DRONE_SESSION_SECRET=""
    # export DRONE_SESSION_EXPIRES=""

    # custom database settings
    # export DRONE_DATABASE_DRIVER=""
    # export DRONE_DATABASE_DATASOURCE=""

    # github configuration
    # export DRONE_GITHUB_CLIENT=""
    # export DRONE_GITHUB_SECRET=""
    # export DRONE_GITHUB_OPEN=false

    # email configuration
    # export DRONE_SMTP_HOST=""
    # export DRONE_SMTP_PORT=""
    # export DRONE_SMTP_FROM=""
    # export DRONE_SMTP_USER=""
    # export DRONE_SMTP_PASS=""

    # worker nodes
    # these are optional. If not specified Drone will add
    # two worker nodes that connect to $DOCKER_HOST
    # export DRONE_WORKER_NODES="tcp://0.0.0.0:2375,tcp://0.0.0.0:2375"

    echo $$ > /var/run/droned.pid
    # exec sudo -u droned \
    #  DRONE_SERVER_PORT=$DRONE_SERVER_PORT \
    #  DRONE_GIHUB_CLIENT=$DRONE_GIHUB_CLIENT \
    #  /usr/local/bin/droned >> /var/log/droned.log 2>&1
    # exec sudo -u droned \
    exec sudo \
     /usr/local/bin/droned --config=/etc/drone/drone.toml >> /var/log/droned.log 2>&1
end script

pre-start script
    echo "[`date -u +%Y-%m-%dT%T.%3NZ`] (sys) Starting" >> /var/log/droned.log
end script

pre-stop script
    rm /var/run/droned.pid
    echo "[`date -u +%Y-%m-%dT%T.%3NZ`] (sys) Stopping" >> /var/log/droned.log
end script

```

Drone parameters can be changed via environment variables in the upstart script or you can attach these environment variables to the instance in the Elastic Beanstalk configuration (in the AWS UI).
Or you can use a special `drone.toml` configuration file:

```ini
# Drone configuration
[server]
port=":8080"

#####################################################################
# SSL configuration
#
# [server.ssl]
# key=""
# cert=""

#####################################################################
# Assets configuration
#
# [server.assets]
# folder=""

# [session]
# secret=""
# expires=""

#####################################################################
# Database configuration, by default using SQLite3.
# You can also use postgres and mysql. See the documentation
# for more details.

[database]
driver="sqlite3"
datasource="/var/lib/drone/drone.sqlite"

[github]
client="xxxxxxxxxxxxxxxxxxxx"
secret="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
# orgs=[]
# open=true

#####################################################################
# SMTP configuration for Drone. This is required if you plan
# to send email notifications for build statuses.
#
[smtp]
host="email-smtp.us-east-1.amazonaws.com"
port="25"
from="myemail@gmail.com"
user="XXXXXXXXXXXXXXXXXXXX"
pass="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# [worker]
# nodes=[
#   "unix:///var/run/docker.sock",
#   "unix:///var/run/docker.sock"
# ]
[worker]
nodes=[
  "unix:///var/run/docker.sock"
]
```

To integrate Drone CI with github, you will need to create an application and generate client and secret tokens, see [details here](http://readme.drone.io/setup/config/github/).

That's all and now if you launch an environment with this configuration you will have Drone CI running.
Access it via url like `your_eb_environment_url.elasticbeanstalk.com:8080`.

# Setup Drone users

In the configuration above we didn't set the option to open new user registration to drone, so random people will not see your repositories and tests.
Instead you will need to explicitly invite all the people who need an access.

First, login with github as the repository owner. This user will become Drone CI admin and will be able to invite other users.
Now select `Users` in Drone menu and invite more users (using github accounts).

If you have problems with user setup, check [this issue](https://github.com/drone/drone/issues/553#issuecomment-58988210).

# Persist Drone CI users using custom API image

We set up Drone CI to use local sqlite database, it is easy, but the problem is that when your instance is terminated and launched again you will lose all user accounts.

So when the setup is done the good idea is to make an image of the running instance and then set it as machine image for the Elastic Beanstalk environment:

- Do the following once your Drone is up and running and you added all the users
- Open EC2 instances page in AWS UI, select the instance with Drone and select an action `Image -> Create image` for it
- Open `AMIs` page and wait until image is created, get the AMI ID (like ami-d2faa5b0)
- Go to Elastic Beanstalk environment, Configuration, Instances and set `Custom AMI ID`

Now if you instance is re-created all the settings will stay.
The drawback is that you'll need to repeat the process once you add more users.
Alternative is to use external RDS instance with MySql as Drone database.

# How to run build locally

To run the build manually, on your local machine, use the following command (you also need to install docker and drone locally):

```bash
sudo drone build
```

You can also run build manually on the EC2 server if you ssh to it and run:

```bash
# for some reason it doesn't work without full path under sudo:
$ sudo /usr/local/bin/drone build
```

# Custom Docker image

For your drone environment, you can choose one of existing docker images, check [the docker hub](https://registry.hub.docker.com/).

But custom image with additional setup steps can speed up the build process, because you don't need to wait for dependencies install on each build.

I use [an automaited build feature of docker hub](https://docs.docker.com/docker-hub/builds/) which means that I have a [github repository with docker file and description](https://github.com/serebrov/centos-python2.7-java).

Every time I push new Dockerfile version to this repository the image is re-build and becomes [available](https://registry.hub.docker.com/u/serebrov/centos-python2.7-java/) on the docker hub.

Note: if you modify a Dockerfile and have already running Drone then it will not see the change. By default image is fetched only once.
To fix this - add `:latest` tag to the image name, trigger a build, drone will update the image. See [this pull request](https://github.com/drone/drone/pull/909/files) for details.

I didn't try it, but probably this issue can also be fixed in a one of following ways:

1) rebuild the elastic beanstalk environment, so everything will be re-built from scratch

2) use docker directly to pull the new version of the image
