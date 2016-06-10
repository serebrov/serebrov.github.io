#!/usr/bin/env bash

MYSQL="mysql -h$MYSQL_PORT_3306_TCP_ADDR -P$MYSQL_PORT_3306_TCP_PORT -uroot -p$MYSQL_ENV_MYSQL_ROOT_PASSWORD"
echo $MYSQL

DB_SCRIPTS="*.sql"
if [[ "$1" != "" ]]; then
    DB_SCRIPTS="$1"
    echo Use single script $DB_SCRIPTS
fi

for dump in $DB_SCRIPTS
do
  filename=$(basename $dump)
  DB="${filename%.*}"
  echo $DB
  echo DROP DATABASE IF EXISTS $DB | $MYSQL  -v
  echo CREATE DATABASE $DB DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci | $MYSQL -v
  $MYSQL $DB -v < $filename 1> /dev/null 2> error.tmp 
  cat error.tmp
  rm error.tmp
  echo Finish.
done
