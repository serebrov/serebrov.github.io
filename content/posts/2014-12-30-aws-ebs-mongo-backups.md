---
title: AWS OpsWorks - setup mongodb ebs volume backups
date: 2014-12-30
tags: [aws, mongodb]
type: note
url: "/html/2014-12-30-aws-ebs-mongo-backups.html"
---

I described how to setup [mongodb on EC2 using OpsWroks](http://serebrov.github.io/html/2014-12-19-aws-opsworks-mongo-and-nodejs.html) and here is how to setup mongo data backups.

In my case all mongo data is stored on the same EBS volume so I just need to make a volume snapshot.
<!-- more -->
The relevant part from the [mongodb docs](http://docs.mongodb.org/ecosystem/tutorial/backup-and-restore-mongodb-on-amazon-ec2/):

```
    Backup with --journal

    The journal file allows for roll forward recovery.
    The journal files are located in the dbpath
    directory so will be snapshotted at the same time as the database files.
    If the dbpath is mapped to a single EBS volume then proceed to Backup
    the Database Files.
    If the dbpath is mapped to multiple EBS volumes, then in order to guarantee
    the stability of the file-system you will need to Flush and Lock
    the Database.
    NOTE
    Snapshotting with the journal is only possible if the journal resides
    on the same volume as the data files, so that one snapshot operation
    captures the journal state and data file state atomically.
```

This is my case - I have all data on the same EBS volume and `journal` option is [enabled by default](http://docs.mongodb.org/v2.2/reference/mongod/#cmdoption--journal) for MongoDB 2.0 and higher on 64-bit systems.
In other cases it is necessary to [flush and lock the database](http://docs.mongodb.org/ecosystem/tutorial/backup-and-restore-mongodb-on-amazon-ec2/#flush-and-lock-the-database). This method is supported by the [ec2-consistent-snapshot tool](https://github.com/alestic/ec2-consistent-snapshot).

My solution is based on the modified version of [aws-snapshot-tool](https://github.com/evannuil/aws-snapshot-tool).
I wanted a completely automated setup where I don't need to take manual steps like assigning tags to the volumes I need to backup.

The process I have now does this:
* There is a special 'ec2-backup' chef recipe which I assign to the instance (or instances) which volumes I need to backup
* This recipe is added to the mongodb layer in OpsWorks, so every mongo instance will have it
* Recipes assigns 'MakeSnapshot'=True tag to the instance
* Recipe also sets up cron jobs to perform daily, weekly and monthly backups
* Snapshots are created by the aws snapshot tool launched by cron
* Aws snapshot tool also sends results via SNS and I get backup notifications by email

The recipe (`ec2-backup/recipes/default.rb`) looks like this:

```ruby

# see https://github.com/stuart-warren/chef-aws-tag

# Assign tag to the instance
include_recipe "aws"
tags = {
  "MakeSnapshot" => "True"
}
aws_resource_tag node['ec2']['instance_id'] do
    tags(tags)
    action :update
end

# Create directory where snapshot tool will be stored
directory "/srv/backup" do
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

# Copy the snapshot tool to /srv/backup
cookbook_file "makesnapshots.py" do
  path "/srv/backup/makesnapshots.py"
  action :create
end

# Copy the snapshot tool config to /srv/backup
cookbook_file "config.py" do
  path "/srv/backup/config.py"
  action :create
end

# Setup a cron job for daily backups
cron "backup-daily" do
  path "/usr/local/bin:$PATH"
  hour "1"
  minute "30"
  weekday '1-6'
  command "cd /srv/backup && /usr/bin/python makesnapshots.py day 2>&1 |/usr/bin/logger -t \"CRON: makenapshot\""
end

# Setup a cron job for weekly backups
cron "backup-weekly" do
  path "/usr/local/bin:$PATH"
  hour "2"
  minute "30"
  weekday '7'
  command "cd /srv/backup && /usr/bin/python makesnapshots.py week 2>&1 |/usr/bin/logger -t \"CRON: makenapshot\""
end

# Setup a cron job for monthly backups
cron "backup-monthly" do
  path "/usr/local/bin:$PATH"
  hour "3"
  minute "30"
  day '1'
  command "cd /srv/backup && /usr/bin/python makesnapshots.py month 2>&1 |/usr/bin/logger -t \"CRON: makenapshot\""
end
```

Under the recipe files folder (`ec2-backup/files/default/`) I have a modified copy of the aws-snapshot-tool.
The recipe folder layout is this:

```bash
├── Berksfile
├── ec2-backup
│   ├── files
│   │   └── default
│   │       ├── config.py
│   │       ├── makesnapshots.py
│   ├── metadata.rb
│   └── recipes
│       └── default.rb
```

The `Berksfile` contains dependency info (only aws is relevant to ec2-backup recipe):

```ruby
source 'https://supermarket.getchef.com'

cookbook 'mongodb'
cookbook 'aws', '>= 0.2.4'
```

My version of the makesnapshots.py is [here](https://gist.github.com/serebrov/38f8c2d47c532243d05a).
My modification was to allow tagging instances instead of volumes.
There is already a similar pull request in the [original repository](https://github.com/evannuil/aws-snapshot-tool/pull/19) so I didn't submit my change back.
There is also one new option in the config.py (see the full config example [here](https://github.com/evannuil/aws-snapshot-tool/blob/559c1f6cf77b87c66c07b177451e76dcccc385fa/config.sample)):

```python
    ...
    # Set to True to use intance tags, False - volume tags
    'use_instance_tag': True,
    ...
```

That's all, now I have mongo data backups with email notifications.

Links
--------
[MongoDB documentation - backup and restore on Amazon EC2](http://docs.mongodb.org/ecosystem/tutorial/backup-and-restore-mongodb-on-amazon-ec2/)

[ec2-consistent-snapshot tool](https://github.com/alestic/ec2-consistent-snapshot)

[aws-snapshot-tool](https://github.com/evannuil/aws-snapshot-tool) and related post [Automated Amazon EBS volume snapshots with boto](http://www.coresoftwaregroup.com/blog/automated-amazon-ebs-volume-snapshots-with-boto)

[Bash script for Automatic EBS Snapshots and Cleanup on Amazon Web Services](https://github.com/CaseyLabs/aws-ec2-ebs-automatic-snapshot-bash) and related [post](https://www.caseylabs.com/automated-ebs-volume-snapshot-script-for-linux-bash/)

[ec2-automate-backup tool](https://github.com/colinbjohnson/aws-missing-tools/tree/master/ec2-automate-backup) and related [post](http://www.cloudar.be/awsblog/automating-snapshotsbackups-of-ec2-ebs-volumes/) and another [one]( http://www.nerdpolytechnic.org/?p=89)

[automated-ebs-snapshots tool](https://github.com/skymill/automated-ebs-snapshots)

[DevOps Backup in Amazon EC2 article](https://medium.com/aws-activate-startup-blog/devops-backup-in-amazon-ec2-190c6fcce41b)

[Stackoverflow: MongoDb EC2 EBS backups](http://stackoverflow.com/questions/18319942/mongodb-ec2-ebs-backups)

[Automated amazon ebs snapshot backup script with 7 day retention](http://www.stardothosting.com/blog/2012/05/automated-amazon-ebs-snapshot-backup-script-with-7-day-retention/)

[Mongodb to Amazon s3 Backup Script](https://github.com/RGBboy/mongodb-s3-backup)

[OpsWorks docs - Running Cron Jobs](http://docs.aws.amazon.com/opsworks/latest/userguide/workingcookbook-extend-cron.html)

[Chef - cron resource](https://docs.chef.io/resource_cron.html)

[Chef - file resource](https://docs.chef.io/resource_file.html) and [cookbook_file](https://docs.chef.io/chef/resources.html#cookbook-file)

[Chef - directory resource](https://docs.chef.io/resource_directory.html)
