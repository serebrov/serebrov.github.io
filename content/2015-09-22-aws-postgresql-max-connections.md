---
title: AWS PostgreSQL RDS - remaining connection slots are reserved error
date: 2015-09-22
tags: aws,rds,postgresql
---

Today I had a problem with PostgreSQL connection, both my application and psql tool returned an error:

```bash
FATAL:  remaining connection slots are reserved for non-replication superuser connections
```

The PostgreSQL server was running on the db.t1.micro RDS instance and the 'Current activity' column showed '22 connections' and a red line which should represent a connection limit was far away from the 22 value.

<!-- more -->

Here is how it looked:

![cwl-setup.config, click to preview](files/2015-09-22-22-connections.png).

And this connection information is actually misleading.
After sometime, when database load went down, I was able to login with psql to check max_connections parameter:

```sql
template1=> show max_connections;
  max_connections
-----------------
 26
(1 row)
```

This setting (max_connection) can also be found in the RDS UI, under "Parameter Groups", but the value there is set as `{DBInstanceClassMemory/31457280}`, so it is complex to be sure about the actual value.
The db.t1.micro instance has 1GB memory, and calculation like `1024*1024*1024/31457280` gives around 36, while actually it is 26.

The default value can be changed, for this it is necessary to create the new parameter group, using the default group as parent and then edit the max_connection value.
But it looks dangerous to do on production, because more connections will consume more memory and instead of connection limit errors you can end up with out of memory errors.
So I decided to change the instance type to db.t2.small, it costs twice more, but it has 2GB RAM and default max_connections value is 60.

In my case the higher connection consumption was not something unexpected, the Elastic Beanstalk scaled the application to 6 EC2 instances under load. Each instance runs a flask application with several threads, so they can easily consume around 20 connections.
To actually make sure that everything is OK with connections handling, run the following query:

```sql
template1=> select * from pg_stat_activity;

 datid |    datname     |  pid  | usesysid |  usename   | application_name |  client_addr  | client_hostname | client_port |         backend_start         |
xact_start          |          query_start          |         state_change          | waiting | state  | backend_xid | backend_xmin |              query
-------+----------------+-------+----------+------------+------------------+---------------+-----------------+-------------+-------------------------------+----------
--------------------+-------------------------------+-------------------------------+---------+--------+-------------+--------------+---------------------------------
 16384 | rdsadmin       |  3155 |       10 | rdsadmin   |                  |               |                 |             |                               |
                    |                               |                               |         |        |             |              | <insufficient privilege>
 16395 | myapp         |  3287 |    16397 | production |                  | 192.33.17.76  |                 |       51365 | 2015-09-22 16:13:04.800089+00 |
                    | 2015-09-22 17:07:13.384317+00 | 2015-09-22 17:07:13.384341+00 | f       | idle   |             |              | COMMIT
 16395 | myapp         |  3562 |    16397 | production |                  | 192.33.17.76  |                 |       51393 | 2015-09-22 16:14:13.953165+00 |
                    | 2015-09-22 17:07:21.216509+00 | 2015-09-22 17:07:21.216581+00 | f       | idle   |             |              | ROLLBACK
 16395 | myapp         |  3563 |    16397 | production |                  | 192.33.9.234  |                 |       33022 | 2015-09-22 16:14:13.9628+00   |
                    | 2015-09-22 17:07:14.379956+00 | 2015-09-22 17:07:14.379975+00 | f       | idle   |             |              | COMMIT
 16395 | myapp         |  3564 |    16397 | production |                  | 192.33.9.234  |                 |       33023 | 2015-09-22 16:14:13.971432+00 |
                    | 2015-09-22 17:07:18.301739+00 | 2015-09-22 17:07:18.301812+00 | f       | idle   |             |              | ROLLBACK
 16395 | myapp         |  3565 |    16397 | production |                  | 192.33.17.76  |                 |       51394 | 2015-09-22 16:14:13.988195+00 |
 ...
     1 | template1      | 17412 |    16386 | root       | psql             | 192.33.16.168 |                 |       35311 | 2015-09-22 17:07:21.814207+00 | 2015-09-2
2 17:07:48.32563+00 | 2015-09-22 17:07:48.32563+00  | 2015-09-22 17:07:48.325633+00 | f       | active |             |      1440784 | select * from pg_stat_activity;
(16 rows)
```

Here you can see all the connections, queries and last activity time for each connection, so it should be easy to see if there are any hanging connections.


# Links

[Stackoverflow: Heroku “psql: FATAL: remaining connection slots are reserved for non-replication superuser connections”](https://stackoverflow.com/questions/13640871/heroku-psql-fatal-remaining-connection-slots-are-reserved-for-non-replication)

[Stackoverflow: Heroku “psql: FATAL: remaining connection slots are reserved for non-replication superuser connections”](http://stackoverflow.com/questions/11847144/heroku-psql-fatal-remaining-connection-slots-are-reserved-for-non-replication)

[Stackoverflow: Amazon RDS (postgres) connection limit?](http://stackoverflow.com/questions/20106536/amazon-rds-postgres-connection-limit)

[Stackoverflow: Flask unittest and sqlalchemy using all connections](http://stackoverflow.com/questions/18291180/flask-unittest-and-sqlalchemy-using-all-connections)

[Stackoverflow: PostgreSQL ERROR: no more connections allowed](http://serverfault.com/questions/577712/postgresql-error-no-more-connections-allowed)
