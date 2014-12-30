---
date: 2014-12-30
tags: aws,mongodb
---
AWS - Deployment via OpsWorks from the command line
=======================================

Below is a simple python script which performs app deployment using OpsWorks API.
Script performs following steps
- Execute 'update_custom_cookbooks' deployment command and wait for successful completion (or stop with an error)
- Execute 'deploy' command and wait for completion

At the top there are aws configuration parameters (aws_access_key, aws_secret_key) - these can be left empty if the script is launched on the AWS instance which has IAM role assigned.

```python
#!/usr/bin/python

import boto.opsworks
from datetime import datetime
import time
import sys
import logging

stack_id="mystackid" # see this in the opsworks stack properties
app_id="myappid" # see this in the opsworks app properties
aws_access_key = "my_access_key"
aws_secret_key = "my_secret_key"
ec2_region_name = 'us-east-1' # your region name
# see region endpoints - http://docs.aws.amazon.com/general/latest/gr/rande.html
ec2_region_endpoint = 'region_endpoint'

def wait_for_deployment(deployment_id):
    print('Waiting for deployment %s to complete' % deployment_id)
    while True:
        result = opsworks.describe_deployments(deployment_ids=[deployment_id])
        data = result['Deployments'][0]
        if data['Status'] == 'running':
            sys.stdout.write('.')
        elif data['Status'] == 'successful':
            print('Done %s' % deployment_id)
            return
        elif data['Status'] == 'failed':
            print('Failed %s' % deployment_id)
            raise Exception('Deployment failed')
        else:
            raise Exception('Unknown deployment stauts: %s' % data['Status'])
        sys.stdout.flush()
        time.sleep(3)

if aws_access_key:
    opsworks = boto.opsworks.connect_to_region(ec2_region_name, aws_access_key_id=aws_access_key, aws_secret_access_key=aws_secret_key)
else:
    opsworks = boto.opsworks.connect_to_region(ec2_region_name)

result = opsworks.create_deployment(stack_id, {"Name":"update_custom_cookbooks"}, app_id)
print('Update custom cookbooks %s' % result)
wait_for_deployment(result['DeploymentId'])

result = opsworks.create_deployment(stack_id, {"Name":"deploy"}, app_id)
print('Deploy %s' % result)
wait_for_deployment(result['DeploymentId'])

```
