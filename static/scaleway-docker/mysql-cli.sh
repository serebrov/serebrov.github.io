#!/usr/bin/env bash

# NOTE: this is another container
docker run -it --link web-mysql:mysql --rm mysql sh -c 'exec mysql -h"$MYSQL_PORT_3306_TCP_ADDR" -P"$MYSQL_PORT_3306_TCP_PORT" -uroot -p"$MYSQL_ENV_MYSQL_ROOT_PASSWORD"'

# the following can be useful to run dumps, from the dir where dumps are, run this command:
# docker run -it -v $(pwd):/home --link web-mysql:mysql --rm mysql bash
