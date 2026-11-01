---
title: "Elastic Beanstalk - how to configure access to the external RDS database"
date: 2023-10-28
tags: [aws, eb, rds]
type: note
url: "/html/2023-10-28-elastic-beanstalk-rds-access.html"
---

I used to configure ElasticBeanstalk access to the external RDS database by editing inbound rules for the security group attached to the database.
This is inconvenient because there is always a risk of breaking something, especially if there are several environments accessing the database and we have multiple inbound rules.

A more convenient method is to use a "proxy" security group:

* Create a new security group named `rds-{database name}-access`
* Add this group to the RDS security group inbound rules, allowing access to the DB port (such as 5432 for PostgreSQL)
* Add the proxy group to the ElasticBeanstalk security groups

The convenience is that we do not have to edit security groups anymore, we just add the "proxy" group in environment settings.

<!-- more -->

This can be done in the UI, by ticking the checkbox in the list of security groups or by adding a config like this:

```yaml
# Add to .ebextensions/app.config or as a separate *.config file 
option_settings:
  aws:autoscaling:launchconfiguration:
    # Add environment to security groups that allow DB access
    SecurityGroups:
    - rds-db-name-access
    - rds-another-db-name-access
```

Related [documentation](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/rds-external-defaultvpc.html).
