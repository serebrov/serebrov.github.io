#!/usr/bin/env bash

SCRIPT_PATH=`dirname $0`
SCRIPT_PATH=$(readlink -f $SCRIPT_PATH)
echo $SCRIPT_PATH

DB_SCRIPT=""
if [[ "$1" != "" ]]; then
    DB_SCRIPT=$1
fi

docker run -i -v $SCRIPT_PATH/dumps/:/home --link web-mysql:mysql --rm mysql sh -c "cd /home && ./load-dumps.sh $DB_SCRIPT"
