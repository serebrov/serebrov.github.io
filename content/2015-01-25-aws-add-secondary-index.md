---
date: 2015-01-25
tags: aws,dynamodb
---
Amazon DynamoDB - how to add global secondary index
=======================================

At the moment it is not possible to add a secondary index into the existing table.
This feature is [announced](https://forums.aws.amazon.com/ann.jspa?annID=2650) but not yet available.

So the only way is to create a new table and migrate the existing data to it.
This can be done using [Amazon EMR](http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/emr-what-is-emr.html).
<!-- more -->

### Create the new table

The new table can be created from the DynamoDB console or with code like this (in python / [boto](http://boto.readthedocs.org/en/latest/ref/dynamodb.html)):

```python
Table.create(
    'my_table_v2',
    schema = [HashKey('my_hash'), RangeKey('a_range', data_type=NUMBER)],
    global_indexes = [
        GlobalAllIndex('SecondaryIndexName',
            parts=[
                HashKey('my_another_hash'), RangeKey('another_range', data_type=NUMBER)
            ],
            throughput={'read': 1, 'write': 3}
        )
    ],
    throughput={'read': 1, 'write': 3})
```

### Move data from the old table to new table

This is not complex to implement such data transfer also in python / boto, but if there is a lot of data the process can take long time to complete.

In this case it is much more convenient to use EMR for this - process is launched and monitored and all logs are recorded.

Another option is to use AWS Data Pipeline service, see the example of [cross-region data copy](http://docs.aws.amazon.com/datapipeline/latest/DeveloperGuide/dp-crossregion-ddb.html). Table to table data copy can be done in a similar way.

But in my case the AWS Data Pipeline service was not available for the region where DynamoDB was launched, so I used EMR (and actually data pipeline also uses EMR behind the scenes).

Amazon EMR allows to create a step of type 'Hive program' where we can only specify the S3 path to the hive script to run (all other parameters are optional).

So we create and upload to S3 the hive script like shown below and then launch or use existing EMR cluster to transfer the data:

```sql
-- This only removes Hive view for dynamo table, not the table itself
DROP TABLE IF EXISTS my_table;
CREATE EXTERNAL TABLE my_table (my_hash string, a_range bigint, my_another_hash string, another_range bigint)
STORED BY 'org.apache.hadoop.hive.dynamodb.DynamoDBStorageHandler'
TBLPROPERTIES ("dynamodb.table.name" = "my_table",
"dynamodb.column.mapping" = "my_hash:my_hash,a_range:a_range,my_another_hash:my_another_hash,another_range:another_range");

-- The my_table_v2 should alreay exists in dynamo and have the secondary index
DROP TABLE IF EXISTS my_table_v2;
CREATE EXTERNAL TABLE my_table_v2 (my_hash string, a_range bigint, my_another_hash string, another_range bigint)
STORED BY 'org.apache.hadoop.hive.dynamodb.DynamoDBStorageHandler'
TBLPROPERTIES ("dynamodb.table.name" = "my_table_v2",
"dynamodb.column.mapping" = "my_hash:my_hash,a_range:a_range,my_another_hash:my_another_hash,another_range:another_range");

-- Use 90% of read/write throughput
SET dynamodb.throughput.read.percent=0.9;
SET dynamodb.throughput.write.percent=0.9;

-- Copy data from table to table
INSERT INTO TABLE my_table_v2 SELECT * FROM my_table;
```

## Links

[Hive Language Manual](https://cwiki.apache.org/confluence/display/Hive/LanguageManual)

[Hive Operators and User-Defined Functions](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+UDF)

[DynamoDB Guide: Hive Command Examples for Exporting, Importing, and Querying Data in DynamoDB](http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/EMR_Hive_Commands.html)

[EMR Guide: Export, Import, Query, and Join Tables in DynamoDB Using Amazon EMR](http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/EMRforDynamoDB.html)

[Optimizing Performance for Amazon EMR Operations in DynamoDB](http://docs.aws.amazon.com/ElasticMapReduce/latest/DeveloperGuide/EMR_Hive_Optimizing.html)

[Using DynamoDB with Amazon Elastic MapReduce](https://aws.amazon.com/articles/Elastic-MapReduce/28549)

[Stackoverflow: Amazon Elastic MapReduce - mass insert from S3 to DynamoDB is incredibly slow](http://stackoverflow.com/questions/10683136/amazon-elastic-mapreduce-mass-insert-from-s3-to-dynamodb-is-incredibly-slow)

[Amazon DynamoDB, Apache Hive and Leaky Abstractions](http://martinharrigan.blogspot.com/2013/07/amazon-dynamodb-apache-hive-and-leaky.html)

[Amazon AWS: Hive, EMR and DynamoDb](http://blog.singhanuvrat.com/tech/amazon-aws-hive-emr-and-dynamodb)

[Exploring Dynamo DB](https://ariyabala.wordpress.com/2013/09/13/exploring-dynamo-db/)
