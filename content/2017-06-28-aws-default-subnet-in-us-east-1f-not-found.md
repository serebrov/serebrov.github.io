---
title: AWS error - Default subnet in us-east-1f not found
date: 2017-06-29
tags: aws
type: note
---

I suddenly started getting the `Default subnet in us-east-1f not found` error during the ElasticBeanstalk environment update.
<!-- more -->

```text
Failed to deploy application.
Updating load balancer named: awseb-e-t-AWSEBLoa-XXXXXXXXXXXXX failed Reason: Default subnet not found in us-east-1f
Service:AmazonCloudFormation, Message:Stack named 'awseb-e-xxxxxxxxxx-stack' aborted operation.
Current state: 'UPDATE_ROLLBACK_IN_PROGRESS'
Reason: The following resource(s) failed to create: [AWSEBUpdateWaitConditionHandleralanC].
The following resource(s) failed to update: [AWSEBLoadBalancer].
```

And the similar one when trying to create the new environment:

```text
Creating load balancer failed Reason: Default subnet in us-east-1f not found
Created CloudWatch alarm named: awseb-e-tet63me2mx-stack-AWSEBCWLAllErrorsCountAlarm-3XCPMJ1ZGJ18
Stack named 'awseb-e-tet63me2mx-stack' aborted operation.
Current state: 'CREATE_FAILED'
Reason: The following resource(s) failed to create: [AWSEBLoadBalancer].
```

The reason seems to be that new `us-east-1f` availablity zone was added, but the subnet for it wasn't configured (not sure why and if it supposed to be configured automatically).

The solution is to create the subnet manually:

- Open VPC - Subnets
- Click "Create Subnet"
- Select the "Availability Zone" - us-east-1f
- It is neccessary to also specify the "IPv4 CIDR block" - in my case I already had 5 subnets with IP blocks:
  - 172.31.0.0/20
  - 172.31.16.0/20
  - 172.31.48.0/20
  - 172.31.32.0/20
  - 172.31.64.0/20
- I specified the next block - 172.31.80.0/20

ElasticBeanstalk updates started working after that.
