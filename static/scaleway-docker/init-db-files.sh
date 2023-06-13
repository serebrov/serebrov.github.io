#!/usr/bin/env bash

set -e

CONFIG="local"
if [[ "$1" != "" ]]; then
    CONFIG=$1
else
    echo Configuration name is not specified. Using 'local' config.
fi

if [[ "$CONFIG" == "production" ]]; then
  eval "$(docker-machine env scaleway)"
  docker-machine ip scaleway
  set +a
  export | grep DOCKER
fi

echo "We are to drop and recreate the databases for all apps."
if [[ "$CONFIG" == "production" ]]; then
  read -p "Are you sure? " -n 1 -r
  echo    # (optional) move to a new line
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
      exit 1
  fi
  docker-machine ssh scaleway pwd
  docker-machine ssh scaleway apt-get install -y postfix mutt
  docker-machine scp -r ./config/web-cron scaleway:/etc/cron.d/
  docker-machine scp -r ./config/.s3cfg scaleway:/root
  docker-machine ssh scaleway rm -rf /root/dumps
  docker-machine ssh scaleway mkdir /root/dumps
  docker-machine scp mysql/dumps/load-dumps.sh scaleway:/root/dumps/load-dumps.sh
  docker-machine scp -r mysql/dumps/projecta.sql scaleway:/root/dumps/projecta.sql
  docker-machine scp -r mysql/dumps/projectb.sql scaleway:/root/dumps/projectb.sql
  docker-machine scp mysql/init-db.sh scaleway:/root
  docker-machine ssh scaleway ./init-db.sh
  # copy files
  docker-machine scp -r projecta/redmine/files scaleway:/var/web/projecta/
  docker-machine scp -r projectb/redmine/assets scaleway:/var/web/projectb/
else
  ./mysql/init-db.sh
fi
