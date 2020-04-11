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
    # will run ./build/projecta.com.sh
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
