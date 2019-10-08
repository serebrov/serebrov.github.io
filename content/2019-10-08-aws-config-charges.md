---
title: AWS Config - Unexpected Charges and Data Analysis
date: 2019-10-08
tags: aws
type: note
---

I started seeing an increased charge in billing for AWS Config service in one of the accounts, it increased from around $5 to $100 per month.
And I didn't even remember if I enabled and configured it.

I could not get any details from AWS Cost Explorer besides that charges are in the same region where our app is running.

<!-- more -->

The confusing part was a note in the AWS Config management console:

> Why am I seeing this page?
> You can now use Config Rules to check configurations recorded by AWS Config. These steps will update your settings and permissions to use Config Rules.
> To use AWS Config without Config Rules, click here. When you are ready to try Config Rules, update your settings by referring to our documentation.

So it even looked like we didn't configure AWS Config at all and the questions I had were:

1) Why are we charged for AWS Config?

2) Can we disable it?

3) How can we access the results of AWS Config? (We were charged for something, which might be useful - how to access this data?)

The [AWS Config pricing](https://aws.amazon.com/config/pricing/) page was also a bit misleading - what caught my eye was the table with rule evaluation prices (and I didn't have any rules defined).

Only after reading through the examples, I found that they also use some "configuration items" to calculate the price, not only rules evaluations.
The thing I missed was at the very top: `You pay $0.003 per configuration item recorded in your AWS account per AWS Region.` (I jumped over this part initially right into the rules pricing table).

It appears, that AWS Config was enabled and some automation in our account caused the large number of configuration items (changes to the configuration) to be recorded.
The guide on how to get and query the collected data (its on S3) can be found [here](https://aws.amazon.com/premiumsupport/knowledge-center/retrieve-aws-config-items-per-month/).

The procedure is following:

* Go to AWS Config settings, check the bucket name
* Go to S3, find that bucket and go into it to get the path to the logs
* The path will be something like this: `s3://aws-config-bucket-123456789123/AWSLogs/123456789123/Config/us-east-1`
* Go to [AWS Athena](https://console.aws.amazon.com/athena/home), create external table and query the data

The table can be created using from query editor.
First, create the database:

```sql
CREATE DATABASE s3data
```

Then, create the table for AWS Config data:

```sql
CREATE EXTERNAL TABLE awsconfig (
         fileversion string,
         configSnapshotId string,
         configurationitems ARRAY < STRUCT < configurationItemVersion : STRING,
         configurationItemCaptureTime : STRING,
         configurationStateId : BIGINT,
         awsAccountId : STRING,
         configurationItemStatus : STRING,
         resourceType : STRING,
         resourceId : STRING,
         resourceName : STRING,
         ARN : STRING,
         awsRegion : STRING,
         availabilityZone : STRING,
         configurationStateMd5Hash : STRING,
         resourceCreationTime : STRING > > 
)
ROW FORMAT SERDE 'org.apache.hive.hcatalog.data.JsonSerDe' LOCATION 's3://aws-config-bucket-123456789123/AWSLogs/123456789123/Config/us-east-1/'
```

Replace the `LOCATION` path with actual path on S3.
Now we can query the `awsconfig` table to see how many and which items were created, for example:

```sql
  SELECT result.configurationitemcapturetime,
         count(result.configurationitemcapturetime) AS NumberOfChanges
    FROM (
          SELECT regexp_replace(
                    configurationItem.configurationItemCaptureTime, '(.+)(T.+)', '$1'
                 ) AS configurationitemcapturetime
            FROM s3data.awsconfig
           CROSS JOIN UNNEST(configurationitems) AS t(configurationItem)
           WHERE "$path" LIKE '%ConfigHistory%'
             AND configurationItem.configurationItemCaptureTime >= '2019-10-01T%'
             AND configurationItem.configurationItemCaptureTime <= '2019-10-10T%'
       ) result
GROUP BY result.configurationitemcapturetime
ORDER BY result.configurationitemcapturetime
```

The above will show number of configuration items created per day.
The `configurationitems` field is a JSON object, so we `UNNEST` and join it to access the columns inside JSON.

```
    capturetime    NumberOfChanges
1   2019-10-01     4279
2   2019-10-02     4254
3   2019-10-03     4307
4   2019-10-04     3765
5   2019-10-05     134
6   2019-10-06     7
7   2019-10-07     9
8   2019-10-08     2
```

This is how to get a data sample:

```sql
SELECT configurationItem.configurationItemVersion,
       configurationItem.configurationItemCaptureTime as fullTime,
       configurationItem.configurationStateId,
       configurationItem.awsAccountId,
       configurationItem.configurationItemStatus,
       configurationItem.resourceType,
       configurationItem.resourceId,
       configurationItem.resourceName,
       configurationItem.aRN,
       configurationItem.awsRegion,
       configurationItem.availabilityZone,
       configurationItem.configurationStateMd5Hash,
       configurationItem.resourceCreationTime
  FROM s3data.awsconfig
 CROSS JOIN UNNEST(configurationitems) AS t(configurationItem)
 WHERE "$path" LIKE '%ConfigHistory%'
   AND configurationItem.configurationItemCaptureTime >= '2019-10-01T%'
   AND configurationItem.configurationItemCaptureTime <= '2019-10-10T%'
```

```
   capturetime ... configurationitemstatus resourcetype         ... resourcename                      ...
1  2019-10-07      ResourceDeleted         AWS::RDS::DBSnapshot     rds:db-wordpress-2019-09-28-10-23
2  2019-10-07      ResourceDeleted         AWS::RDS::DBSnapshot     rds:db-wordpress-2019-09-29-10-24
3  2019-10-07      ResourceDiscovered      AWS::RDS::DBSnapshot     rds:db-wordpress-2019-10-07-10-23
4  2019-10-07      ResourceDeleted         AWS::RDS::DBSnapshot     rds:db-production-2019-09-28-10-18
5  2019-10-07      OK                      AWS::RDS::DBInstance     db-production
6  2019-10-07      OK                      AWS::RDS::DBInstance     db-wordpress
7  2019-10-07      OK                      AWS::RDS::DBInstance     db-production
8  2019-10-07      OK                      AWS::RDS::DBInstance     db-wordpress
```

And this query fetches data grouped by resource type, name and status:

```sql
  SELECT configurationItem.resourceType,
         configurationItem.resourceName,
         configurationItem.configurationItemStatus,
         COUNT(configurationItem.resourceId) AS NumberOfChanges
    FROM s3data.awsconfig
   CROSS JOIN UNNEST(configurationitems) AS t(configurationItem)
   WHERE "$path" LIKE '%ConfigHistory%'
     AND configurationItem.configurationItemCaptureTime >= '2019-10-07T%'
     AND configurationItem.configurationItemCaptureTime <= '2019-10-08T%'
GROUP BY configurationItem.resourceType
         , configurationItem.resourceName
         , configurationItem.configurationItemStatus
ORDER BY NumberOfChanges DESC
```

```
    resourcetype            resourcename                        configurationitemstatus  NumberOfChanges
1   AWS::RDS::DBInstance    db-wordpress                        OK                       2
2   AWS::RDS::DBInstance    db-production                       OK                       2
3   AWS::RDS::DBSnapshot    rds:db-production-2019-10-07-10-18  ResourceDiscovered       1
4   AWS::RDS::DBSnapshot    rds:db-wordpress-2019-10-07-10-23   ResourceDiscovered       1
5   AWS::RDS::DBSnapshot    rds:db-production-2019-09-28-10-18  ResourceDeleted          1
6   AWS::RDS::DBSnapshot    rds:db-wordpress-2019-09-29-10-24   ResourceDeleted          1
7   AWS::RDS::DBSnapshot    rds:db-wordpress-2019-09-28-10-23   ResourceDeleted          1
```

Using these queries, it should be possible to get an idea of what is happening, in my case it was misbehaving ElasticBeanstalk environment with bad health that was constantly re-creating all the resources.
