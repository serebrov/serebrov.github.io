---
title: Amazon DynamoDB, EMR and Hive notes
date: 2015-01-24
tags: [aws, dynamodb, emr, hive]
type: note
url: "/html/2015-01-24-aws-dynamodb-emr-hive.html"
---

First you need the EMR cluster running and you should have ssh connection to the master instance like described in the [getting started tutorial](http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/emr-get-started.html).

Now it is possible to run Hive commands in few following ways:

* Connect via ssh, launch hive and run commands interactively
* Create a script file with commands, upload it to S3 and launch as a ERM 'Hive program' [step](http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/CLI_CreatingaJobFlowUsingHive.html)
* Run it from Hue web-interface (see below)

<!-- more -->

### Connect to Hue
Hue is a Hadoop [web interface](http://gethue.com/). It is automatically installed when EMR cluster is launched.
The recommended way to connect to Hue is via [ssh tunnel](http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/gsg-hue.html), [see also](http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/accessing-hue.html).

But there is a simpler way (but less secure) - open the 8888 port on the master EMR instance:

* open security groups in EC2 console, find ElasticMapReduce-master and add
* Custom TCP Rule, Port 8888, Anywhere
* Check EMR master public DNS
* Open Hue: http://ec2-XX-XXX-XX-XXX.region-name.compute.amazonaws.com:8888/

### Analyze DynamoDB data with Hive

To analyze the DynamoDB data there are following options:

* Create the external Hive table pointing to DynamoDB table and make queries against it (slow and consumes DynamoDB resources)
* Export data from dynamo to the native Hive table then query this data off-line
* Export data from dynamo to S3 and then query it, in this case queries are a bit slower than for a native Hive table, but data persists on S3, so it is possible to terminate the cluster and then launch it again when necessary

Example of the script to move data from dynamo to hive native table:

```sql
-- Here you can drop/create an external table at any time - this will not affect real data
CREATE EXTERNAL TABLE dynamo_table (hash string, range bigint, data string)
STORED BY 'org.apache.hadoop.hive.dynamodb.DynamoDBStorageHandler'
TBLPROPERTIES ("dynamodb.table.name" = "mytable",
"dynamodb.column.mapping" = "hash:hash,range:range,data:data");

CREATE TABLE hive_table (hash string, range bigint, data string);

SET dynamodb.throughput.read.percent=0.9;

INSERT OVERWRITE TABLE hive_table SELECT * FROM dynamo_table;
```

Example of the script to move data from dynamo to S3:

```sql
CREATE EXTERNAL TABLE dynamo_table (hash string, range bigint, data string)
STORED BY 'org.apache.hadoop.hive.dynamodb.DynamoDBStorageHandler'
TBLPROPERTIES ("dynamodb.table.name" = "mytable",
"dynamodb.column.mapping" = "hash:hash,range:range,data:data");

CREATE EXTERNAL TABLE s3_table(hash string, range bigint, data string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
LOCATION 's3://my-bucket-name/2015-01-24-dynamo-table-data/';

INSERT OVERWRITE TABLE s3_table SELECT * FROM dynamo_table;

```

### Hive - timestamp to date conversions

Examples of some queries to convert the timestamp to date string:

```sql
-- Convert timestamp to date in UTC+2 timezone
select hash, stamp, from_unixtime(stamp, 'y-M-d H:m:sZ+0200') from hive_table limit 10;

-- Select data by date string
select hash, stamp from hive_table where stamp > unix_timestamp('2014-12-25 10:18:41+0200') limit 10;
```

### Execute python script from Hive script

It is possible to transform data in Hive using external python script (see [here](http://andreyfradkin.com/posts/2013/06/15/combining-hive-and-python/) and [here](http://www.lichun.cc/blog/2012/06/wordcount-mapreduce-example-using-hive-on-local-and-emr/)).
And using a fake table it is possible to run the python script from the hive script:

```sql
--
-- Run python script to create test tables on dynamo.
-- Script should be uploaded to tapway-scripts/ on s3
--
CREATE TABLE IF NOT EXISTS empty_src (id string);
add file s3://tapway-scripts/hive.copy.test.py;
select transform (id) using 'hive.copy.test.py' from empty_src;
```

## Links

[Hive Language Manual](https://cwiki.apache.org/confluence/display/Hive/LanguageManual)

[Hive Operators and User-Defined Functions](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+UDF)

[DynamoDB Guide: Hive Command Examples for Exporting, Importing, and Querying Data in DynamoDB](http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/EMR_Hive_Commands.html)

[EMR Guide: Export, Import, Query, and Join Tables in DynamoDB Using Amazon EMR](http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/EMRforDynamoDB.html)

[Optimizing Performance for Amazon EMR Operations in DynamoDB](http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/EMR_Hive_Optimizing.html)

[Using DynamoDB with Amazon Elastic MapReduce](https://aws.amazon.com/articles/Elastic-MapReduce/28549)

[Hive & DynamoDB Pitfalls](http://arjon.es/2014/01/29/hive-dynamodb-pitfalls/)

[Stackoverflow: Amazon Elastic MapReduce - mass insert from S3 to DynamoDB is incredibly slow](http://stackoverflow.com/questions/10683136/amazon-elastic-mapreduce-mass-insert-from-s3-to-dynamodb-is-incredibly-slow)

[Amazon DynamoDB, Apache Hive and Leaky Abstractions](http://martinharrigan.blogspot.com/2013/07/amazon-dynamodb-apache-hive-and-leaky.html)

[Amazon AWS: Hive, EMR and DynamoDb](http://blog.singhanuvrat.com/tech/amazon-aws-hive-emr-and-dynamodb)

[Exploring Dynamo DB](https://ariyabala.wordpress.com/2013/09/13/exploring-dynamo-db/)
