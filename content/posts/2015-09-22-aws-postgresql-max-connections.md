---
title: AWS PostgreSQL RDS - remaining connection slots are reserved error
date: 2015-09-22
tags: [aws, rds, postgresql]
type: note
---

Today I had a problem with PostgreSQL connection, both my application and psql tool returned an error:

```bash
FATAL:  remaining connection slots are reserved for non-replication superuser connections
```

The PostgreSQL server was running on the db.t1.micro RDS instance and the 'Current activity' column showed '22 connections' and a red line which should represent a connection limit was far away from the 22 value.

<!-- more -->

Here is how it looked:

![cwl-setup.config, click to preview](/2015-09-22-22-connections.png).

And this connection information is actually misleading - it shows 22 connections and it looks like around 30% consumed.
While actually we already at 100% of connections.

After some time, when the database load went down, I was able to login with psql to check max_connections parameter:

```sql
template1=> show max_connections;
  max_connections
-----------------
 26
(1 row)
```

So we have 26 max connections and, as stated in comments (thanks, Johannes Schickling), there are also 3 connections reserved to superuser.

That means we used 25 connections (22 + 3 reserved) out of 26.

The `max_connection` setting can also be found in the RDS UI, under "Parameter Groups", but the value there is set as `{DBInstanceClassMemory/31457280}`, so it is complex to be sure about the actual value.
The db.t1.micro instance has 1GB memory, and calculation like `1024*1024*1024/31457280` gives around 36, while actually it is 26.

The default value can be changed this way:

- create a new parameter group
- using the default group as parent and then edit the max_connection value
- once done - go to the db instance settings (Modify action) and set the new parameter group.

But for me it seems to be dangerous solution to use in production, because more connections will consume more memory and instead of connection limit errors you can end up with out of memory errors.

So I decided to change the instance type to db.t2.small, it costs twice more, but it has 2GB RAM and default max_connections value is 60.

In my case the higher connection consumption was not something unexpected, the Elastic Beanstalk scaled the application to 6 EC2 instances under load. Each instance runs a flask application with several threads, so they can easily consume around 20 connections.
To actually make sure that everything is OK with connections handling, run the following query:

```sql
template1=> select * from pg_stat_activity;

 datid |  datname | ... |    backend_start    | ... |     query_start     |    state_change     | waiting | state | ... |  query
-------+----------+-----+---------------------+-----+---------------------+---------------------+---------+-------+-----+--------------------------
 ...
 16395 | myapp    | ... | 2015-09-22 16:13:04 | ... | 2015-09-22 17:07:13 | 2015-09-22 17:07:13 | f       | idle  | ... | COMMIT
 16395 | myapp    | ... | 2015-09-22 16:14:13 | ... | 2015-09-22 17:07:21 | 2015-09-22 17:07:21 | f       | idle  | ... | ROLLBACK
 16395 | myapp    | ... | 2015-09-22 16:14:13 | ... | 2015-09-22 17:07:14 | 2015-09-22 17:07:14 | f       | idle  | ... | COMMIT
 16395 | myapp    | ... | 2015-09-22 16:14:13 | ... | 2015-09-22 17:07:18 | 2015-09-22 17:07:18 | f       | idle  | ... | ROLLBACK
 ...
(16 rows)
```

Here you can see all the connections, queries and last activity time for each connection, so it should be easy to see if there are any hanging connections.


# Links

[Stackoverflow: Heroku “psql: FATAL: remaining connection slots are reserved for non-replication superuser connections”](http://stackoverflow.com/questions/11847144/heroku-psql-fatal-remaining-connection-slots-are-reserved-for-non-replication)

[Stackoverflow: Amazon RDS (postgres) connection limit?](http://stackoverflow.com/questions/20106536/amazon-rds-postgres-connection-limit)

[Stackoverflow: Flask unittest and sqlalchemy using all connections](http://stackoverflow.com/questions/18291180/flask-unittest-and-sqlalchemy-using-all-connections)

[Stackoverflow: PostgreSQL ERROR: no more connections allowed](http://serverfault.com/questions/577712/postgresql-error-no-more-connections-allowed)
