---
title: Elastic Beanstalk - how to setup CloudWatch Logs
date: 2015-05-20
tags: aws,eb,cw-logs
---

CloudWatch Logs is an AWS service to collect and monitor system and application logs.
On the top level setup is this:
- install CloudWatch agent to collect logs data and send to CloudWatch Logs service
- define log metric filters to extract useful data, like number of all errors or information about some specific events
- create alarms for metrics to get notifications about logs

All the configuration can be done using the Elastic Beanstalk config. In this case when the new environment is launched or existing environment is updated  the CloudWatch Logs setup is done automatically.

There is an example of the configuration in the Elastic Beanstalk docs - [Using Elastic Beanstalk with Amazon CloudWatch Logs](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.cloudwatchlogs.html).
The `Setting Up CloudWatch Logs Integration with Configuration Files` section briefly describes how to use config examples for different environments, but there is no detailed information about the config files. And config files are complex. It is easy to use examples as is, but it is not that easy to do the setup for own logs.
I will start with the review of the Apache access log example and will show how to change it to collect data from the error log as well.
<!-- more -->

An example for php and python is an archive containing:

```
cloudwatchlogs-apache/
  cwl-setup.config
  eb-logs.config
  cwl-webrequest-metrics.config
```

Files need to be placed under `.ebextensions` folder. I recommend extracting an archive into `.ebextensions/cloudwatchlogs-apache`. You can also put an archive file itself, but it will be not convenient to view/edit configs then.

First two files ([cwl-setup.config](files/cloudwatchlogs-apache/cwl-setup.config) and [eb-logs.config](files/cloudwatchlogs-apache/eb-logs.config)) are generic and can be used as is.
These files will setup CloudWatch Logs agent on the instance and configure Elastic Beanstalk logs publication to S3.

The last one ([cwl-webrequest-metrics.config](files/cloudwatchlogs-apache/cwl-webrequest-metrics.config)) is an example of CloudWatch Logs setup for Apache's access log.

Config file consists of several sections - 'Mappings', 'Outputs', 'Resources'.
There are cross-references between these sections, like filters defined in 'Mappings' section are used later in 'Resources' section for metric filters configuration.

Unfortunately, there is no complete description of this config format in the Elastic Beanstalk documentation.
As I understand this is actually a CloudFormation template but written in yaml (Elastic Beanstalk config format) instead of json (regular CloudFormation template format).

General template structure and information about its sections can be found here:
[CloudFormation - Template Anatomy](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-anatomy.html).

Let's examine a `cwl-webrequest-metrics.config` file.
The first section is 'Mappings', here it is:

```yaml
# Apache access log pattern:
## "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\""
## remote_host  remote_logname  remote_user  time_received "request" status response_size "referrer" "user-agent"
Mappings:
  CWLogs:
    WebRequestLogGroup:
      LogFile: "/var/log/httpd/access_log"
      TimestampFormat: "%d/%b/%Y:%H:%M:%S %z"
    FilterPatterns:
      Http4xxMetricFilter: "[..., status=4*, size, referer, agent]"
      HttpNon4xxMetricFilter: "[..., status!=4*, size, referer, agent]"
      Http5xxMetricFilter: "[..., status=5*, size, referer, agent]"
      HttpNon5xxMetricFilter: "[..., status!=5*, size, referer, agent]"
```

Here we see some definitions like log file path (`LogFile`), log timestamp format (`TimestampFormat`) and filter patterns (`Http4xxMetricfilter`, `HttpNon4xxMetricFilter`, ...).
These definitions work as constants defined at the top of the template and are referred from other sections of the file.

Filter patterns will be used to setup metric filters for the access log.
Here we have patterns which will find all requests with 4XX response code, all requests with non 4XX code, all 5XX responses and all non 5XX responses.

The `TimestampFormat` setting is used by CloudWatch Logs agent to get timestamps for log records, so it is important to verify that format is set correctly.
The timestamp format is the same as used by [python's strptime function](https://docs.python.org/2/library/datetime.html#strftime-strptime-behavior).
Some more information about the format can be found in the CloudWatch Logs agent [setup file](https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py), check around the middle of the file, the description of the `datetime_format` parameter - there is a table with placeholders and examples.

Since timestamp format is the same as used by python, it is easy to test it using python interpreter. Start python in command line and use code like this:

```
  >>> import time
  >>> time.strptime('30/03/09 16:31:32.123', '%d/%m/%y %H:%M:%S.%f')
```

In some cases, it can be complex to set the timestap format because there can be just no placeholders to express the real format in the log.
In this case, try to match at least part of the timestamp.

For example, Apache error log has a timestamp like `Sun May 17 21:59:15.837463 2015`. The problem is that there is a fractional part of the second in the middle, before the year and official python docs doesn't have a placeholder for this case (edit: there is an `%f` for microseconds, but let's pretend we don't know this).

The pattern I used for Apache error log  is `%a %b %d %H:%M:%S` (short weekday, short month name, day, hour:minute:second) and it matches only the start of the timestamp and does not include year. But it works good and I guess that CloudWatch agent takes the current year as default.

Next section in the config file is `Outputs`:

```yaml
Outputs:
  WebRequestCWLogGroup:
    Description: "The name of the Cloudwatch Logs Log Group created for this environments web server access logs. You can specify this by setting the value for the environment variable: WebRequestCWLogGroup. Please note: if you update this value, then you will need to go and clear out the old cloudwatch logs group and delete it through Cloudwatch Logs."
    Value: { "Ref" : "AWSEBCloudWatchLogs8832c8d3f1a54c238a40e36f31ef55a0WebRequestLogGroup"}
```

Here we describe CloudWatch Logs group.
Log group is a top level entity, like "production-apache-errors", "staging-syslog", etc.
Inside the group we have streams, each stream contains log records from some EC2 instance.

Next section is `Resources` where we define AWS resources used in our setup:

```yaml
Resources :
  AWSEBCloudWatchLogs8832c8d3f1a54c238a40e36f31ef55a0WebRequestLogGroup:    ## Must have prefix:  AWSEBCloudWatchLogs8832c8d3f1a54c238a40e36f31ef55a0
    Type: "AWS::Logs::LogGroup"
    DependsOn: AWSEBBeanstalkMetadata
    DeletionPolicy: Retain     ## this is required
    Properties:
      LogGroupName:
        "Fn::GetOptionSetting":
          Namespace: "aws:elasticbeanstalk:application:environment"
          OptionName: WebRequestCWLogGroup
          DefaultValue: {"Fn::Join":["-", [{ "Ref":"AWSEBEnvironmentName" }, "webrequests"]]}
      RetentionInDays: 14
```

Above is the definition of the log group resource.
Notice the usage of "Fn::FunctionName" constructs, the config file also has a mini-language to refer other sections of the config or to join strings.
For example, `{"Fn::Join":["-", [{ "Ref":"AWSEBEnvironmentName" }, "webrequests"]]}` will take Elastic Beanstalk environment name and add '-webrequests' after it, so the log group name will be "environment-webrequests".

Or function call like this (it is used below) `{"Fn::FindInMap":["CWLogs", "WebRequestLogGroup", "TimestampFormat"]}` will look up a `TimestampFormat` value in the `Mappings` config section.

You can find more information on functions here:
- [Elastic Beanstalk - Intrinsic Function Reference](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/intrinsic-function-reference.html)
- [CloudFormation - Intrinsic Function Reference](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html)

Next resource in the `Resources` section is an autoscaling group:

```yaml
  ## Register the files/log groups for monitoring
  AWSEBAutoScalingGroup:
    Metadata:
      "AWS::CloudFormation::Init":
        CWLogsAgentConfigSetup:
          files:
            ## any .conf file put into /tmp/cwlogs/conf.d will be added to the cwlogs config (see cwl-agent.config)
            "/tmp/cwlogs/conf.d/apache-access.conf":
              content : |
                [apache-access_log]
                file = `{"Fn::FindInMap":["CWLogs", "WebRequestLogGroup", "LogFile"]}`
                log_group_name = `{ "Ref" : "AWSEBCloudWatchLogs8832c8d3f1a54c238a40e36f31ef55a0WebRequestLogGroup" }`
                log_stream_name = {instance_id}
                datetime_format = `{"Fn::FindInMap":["CWLogs", "WebRequestLogGroup", "TimestampFormat"]}`
              mode  : "000400"
              owner : root
              group : root
```

Here we describe autoscaling group and say that during the new EC2 instance initialization ([AWS::CloudFormation::Init](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-init.html)) the `/tmp/cwlogs/conf.d/apache-access.conf` file should be created. This is a CloudWatch agent configuration which instructs an agent to collect data from the apache access log.
We also describe a content for this file:

```yaml
content : |
  [apache-access_log]
  ## We take file name from the Mappings - CWLogs - WebRequestLogGroup - LogFile
  file = `{"Fn::FindInMap":["CWLogs", "WebRequestLogGroup", "LogFile"]}`
  ## Log group is a reference to the log group resource we defined above
  log_group_name = `{ "Ref" : "AWSEBCloudWatchLogs8832c8d3f1a54c238a40e36f31ef55a0WebRequestLogGroup" }`
  ## Log stream name is an instance id
  log_stream_name = {instance_id}
  ## date_format for cloudwatch agent is also defined in Mappings section above
  datetime_format = `{"Fn::FindInMap":["CWLogs", "WebRequestLogGroup", "TimestampFormat"]}`
```

You can find more information about the CloudWatch agent configuration [here](http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/AgentReference.html).

Next four resources are metric filters. These filters will extract and count messages with specific status codes from the Apache access log.

```yaml
  #######################################
  ## Cloudwatch Logs Metric Filters

  AWSEBCWLHttp4xxMetricFilter :
    Type : "AWS::Logs::MetricFilter"
    Properties :
      LogGroupName: { "Ref" : "AWSEBCloudWatchLogs8832c8d3f1a54c238a40e36f31ef55a0WebRequestLogGroup" }
      FilterPattern : {"Fn::FindInMap":["CWLogs", "FilterPatterns", "Http4xxMetricFilter"]}
      MetricTransformations :
        - MetricValue : 1
          MetricNamespace: {"Fn::Join":["/", ["ElasticBeanstalk", {"Ref":"AWSEBEnvironmentName"}]]}
          MetricName : CWLHttp4xx

  AWSEBCWLHttpNon4xxMetricFilter :
    Type : "AWS::Logs::MetricFilter"
    DependsOn : AWSEBCWLHttp4xxMetricFilter
    Properties :
      LogGroupName: { "Ref" : "AWSEBCloudWatchLogs8832c8d3f1a54c238a40e36f31ef55a0WebRequestLogGroup" }
      FilterPattern : {"Fn::FindInMap":["CWLogs", "FilterPatterns", "HttpNon4xxMetricFilter"]}
      MetricTransformations :
        - MetricValue : 0
          MetricNamespace: {"Fn::Join":["/", ["ElasticBeanstalk", {"Ref":"AWSEBEnvironmentName"}]]}
          MetricName : CWLHttp4xx

  AWSEBCWLHttp5xxMetricFilter :
    Type : "AWS::Logs::MetricFilter"
    Properties :
      LogGroupName: { "Ref" : "AWSEBCloudWatchLogs8832c8d3f1a54c238a40e36f31ef55a0WebRequestLogGroup" }
      FilterPattern : {"Fn::FindInMap":["CWLogs", "FilterPatterns", "Http5xxMetricFilter"]}
      MetricTransformations :
        - MetricValue : 1
          MetricNamespace: {"Fn::Join":["/", ["ElasticBeanstalk", {"Ref":"AWSEBEnvironmentName"}]]}
          MetricName : CWLHttp5xx

  AWSEBCWLHttpNon5xxMetricFilter :
    Type : "AWS::Logs::MetricFilter"
    DependsOn : AWSEBCWLHttp5xxMetricFilter
    Properties :
      LogGroupName: { "Ref" : "AWSEBCloudWatchLogs8832c8d3f1a54c238a40e36f31ef55a0WebRequestLogGroup" }
      FilterPattern : {"Fn::FindInMap":["CWLogs", "FilterPatterns", "HttpNon5xxMetricFilter"]}
      MetricTransformations :
        - MetricValue : 0
          MetricNamespace: {"Fn::Join":["/", ["ElasticBeanstalk", {"Ref":"AWSEBEnvironmentName"}]]}
          MetricName : CWLHttp5xx
```

Metric filters use filter patterns defined in the `Mappings` section.
Pattern syntax is described [here](https://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/FilterAndPatternSyntax.html) and it is convenient to test patterns in the AWS console:
- Open CloudWatch service in AWS console
- Click `Logs` on the left, select log group on the right
- Click `Create Metric Filter` button

Now you can select existing log data if you already have it or just paste some text from the local log file, enter filter pattern and test it on the log data.

For example, entering the filter like `[timestamp, type = *, ...]` you can see what is taken as a timestamp.
If we have log data like this:

```text
[Thu May 14 16:26:54.396347 2015] [suexec:notice] [pid 2631] AH01232: suEXEC mechanism enabled (wrapper: /usr/sbin/suexec)
[Thu May 14 16:26:54.405887 2015] [auth_digest:notice] [pid 2631] AH01757: generating secret for digest authentication ...
[Thu May 14 16:26:54.406397 2015] [lbmethod_heartbeat:notice] [pid 2631] AH02282: No slotmem from mod_heartmonitor
[Thu May 14 16:26:54.407930 2015] [mpm_prefork:notice] [pid 2631] AH00163: Apache/2.4.10 (Amazon) mod_wsgi/3.5 Python/2.7.5 configured -- resuming normal operations
```

Then the test result for a pattern `[timestamp, type = *, ...]` will be this:

```text
Line Number $timestamp                       $type               $3       ...
1           Thu May 14 16:26:54.396347 2015  suexec:notice       pid 2631
2           Thu May 14 16:26:54.405887 2015  auth_digest:notice  pid 2631
3           Thu May 14 16:26:54.406397 2015  ...
```

Here the data is considered as a space-delimited, so each word becomes a data column. Spaces can be "escaped" with square brackets, like [Thu May 07 07:03:48.655204 2015] will be considered one field.

This way for custom application logs it is better to use square brackets to specify log record fields. For example, it is better to use `[2015-05-14 19:00:03] [WARNING] -- the warning message` instead of `2015-05-14 19:00:03 WARNING -- the warning message`.

Note: in the `Mappings` section we also specify `TimestampFormat`, but it has no effect for filters and only used by CloudWatch agent.

And finally we define alarms which will watch for metrics above and generate SNS notification if we have too many 5XX responses (here we count responses) or if percent of 4XX responses becomes high (here we calculate percent value of 4XX responses).

```yaml
  ######################################################
  ## Alarms

  AWSEBCWLHttp5xxCountAlarm :
    Type : "AWS::CloudWatch::Alarm"
    DependsOn : AWSEBCWLHttpNon5xxMetricFilter
    Properties :
      AlarmDescription: "Application is returning too many 5xx responses (count too high)."
      MetricName: CWLHttp5xx
      Namespace: {"Fn::Join":["/", ["ElasticBeanstalk", {"Ref":"AWSEBEnvironmentName"}]]}
      Statistic: Sum
      Period: 60
      EvaluationPeriods: 1
      Threshold: 10
      ComparisonOperator: GreaterThanThreshold
      AlarmActions:
        - "Fn::If":
            - SNSTopicExists
            - "Fn::FindInMap":
                - AWSEBOptions
                - options
                - EBSNSTopicArn
            - { "Ref" : "AWS::NoValue" }

  AWSEBCWLHttp4xxPercentAlarm :
    Type : "AWS::CloudWatch::Alarm"
    DependsOn : AWSEBCWLHttpNon4xxMetricFilter
    Properties :
      AlarmDescription: "Application is returning too many 4xx responses (percentage too high)."
      MetricName: CWLHttp4xx
      Namespace: {"Fn::Join":["/", ["ElasticBeanstalk", {"Ref":"AWSEBEnvironmentName"}]]}
      Statistic: Average
      Period: 60
      EvaluationPeriods: 1
      Threshold: 0.10
      ComparisonOperator: GreaterThanThreshold
      AlarmActions:
        - "Fn::If":
            - SNSTopicExists
            - "Fn::FindInMap":
                - AWSEBOptions
                - options
                - EBSNSTopicArn
            - { "Ref" : "AWS::NoValue" }

```

More information about `Resources` section:
- [Elastic Beanstalk - Customizing Environment Resources](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-resources.html)
- [Elastic Beanstalk - Customizing AWS Resources](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/template-reference-aeb.html)

## Apache error log setup

To create a CloudWatch Log configuration for another log file do the following:
- Copy `cwl-webrequest-metrics.config` and save under new name into the same folder
- In the `Mappings` section - change the log file path, timestamp format and filter patterns
- In the `AWSEBAutoScalingGroup` resource - change the config file name: `apache-access.conf` to `my-log-name.conf` and change `[apache-access_log]` section name in the content
- Search for `webrequest` and replace all occurences with appropriate name, do the case-insensetive search to change webrequest, WebRequest, etc
- Review filter patterns, metrics and alarms - these will be different for each log file

For example, a config for apache error log can look like this (file `cwl-weberror-metrics.config`):

```yaml
Mappings:
  CWLogs:
    WebErrorLogGroup:
      LogFile: "/var/log/httpd/error_log"
      TimestampFormat: "%a %b %d %H:%M:%S"
    FilterPatterns:
      AllErrorsFilter: "[timestamp, type = *error*, ...]"


Outputs:
  WebErrorCWLogGroup:
    Description: "Apache error log - WebErrorCWLogGroup"
    Value: { "Ref" : "AWSEBCloudWatchLogs8832c8d3f1a54c238a40e36f31ef55a0WebErrorLogGroup"}


Resources :
  AWSEBCloudWatchLogs8832c8d3f1a54c238a40e36f31ef55a0WebErrorLogGroup:
    Type: "AWS::Logs::LogGroup"
    DependsOn: AWSEBBeanstalkMetadata
    DeletionPolicy: Retain     ## this is required
    Properties:
      LogGroupName:
        "Fn::GetOptionSetting":
          Namespace: "aws:elasticbeanstalk:application:environment"
          OptionName: WebErrorCWLogGroup
          DefaultValue: {"Fn::Join":["-", [{ "Ref":"AWSEBEnvironmentName" }, "weberrors"]]}
      RetentionInDays: 14


  AWSEBAutoScalingGroup:
    Metadata:
      "AWS::CloudFormation::Init":
        CWLogsAgentConfigSetup:
          files:
            "/tmp/cwlogs/conf.d/apache-error.conf":
              content : |
                [apache-error_log]
                file = `{"Fn::FindInMap":["CWLogs", "WebErrorLogGroup", "LogFile"]}`
                log_group_name = `{ "Ref" : "AWSEBCloudWatchLogs8832c8d3f1a54c238a40e36f31ef55a0WebErrorLogGroup" }`
                log_stream_name = {instance_id}
                datetime_format = `{"Fn::FindInMap":["CWLogs", "WebErrorLogGroup", "TimestampFormat"]}`
              mode  : "000400"
              owner : root
              group : root


  AWSEBCWLAllErrorsFilter :
    Type : "AWS::Logs::MetricFilter"
    Properties :
      LogGroupName: { "Ref" : "AWSEBCloudWatchLogs8832c8d3f1a54c238a40e36f31ef55a0WebErrorLogGroup" }
      FilterPattern : {"Fn::FindInMap":["CWLogs", "FilterPatterns", "AllErrorsFilter"]}
      MetricTransformations :
        - MetricValue : 1
          MetricNamespace: {"Fn::Join":["/", ["ElasticBeanstalk", {"Ref":"AWSEBEnvironmentName"}]]}
          MetricName : CWLAllErrorRecords


  AWSEBCWLAllErrorsCountAlarm :
    Type : "AWS::CloudWatch::Alarm"
    DependsOn : AWSEBCWLAllErrorsFilter
    Properties :
      AlarmDescription: "Application generated an error in error_log"
      MetricName: CWLAllErrorRecords
      Name: {"Fn::Join":["-", ["ElasticBeanstalk-AWSEBCWLAllErrorsCountAlarm", {"Ref":"AWSEBEnvironmentName"}]]}
      Namespace: {"Fn::Join":["/", ["ElasticBeanstalk", {"Ref":"AWSEBEnvironmentName"}]]}
      Statistic: Sum
      Period: 60
      EvaluationPeriods: 1
      Threshold: 1
      ComparisonOperator: GreaterThanThreshold
      AlarmActions:
        - "Fn::If":
            - SNSTopicExists
            - "Fn::FindInMap":
                - AWSEBOptions
                - options
                - EBSNSTopicArn
            - { "Ref" : "AWS::NoValue" }


```

Note that metrics and alarms are optional and log data will be sent to CloudWatch Logs even if there are no metrics/alarms.
But in this case, it will be necessary to review logs manually and setup metrics and alarms later if needed.

## Links

[Using Elastic Beanstalk with Amazon CloudWatch Logs (+ config examples)](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.cloudwatchlogs.html)

[Amazon CloudWatch Monitoring Scripts for Linux (sample Perl scripts that demonstrate how to produce and consume Amazon CloudWatch custom metrics)](http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/mon-scripts-perl.html)

[AWS Blog: Store and Monitor OS & Application Log Files with Amazon CloudWatch (manual setup, note about elastic beanstalk, information about cloud formation and ops works)](https://aws.amazon.com/blogs/aws/cloudwatch-log-service/)

[Logs Monitoring Using AWS CloudWatch (awslogs agent setup via script + metrics / alarms from the AWS console)](http://www.intelligrape.com/blog/logs-monitoring-using-aws-cloudwatch/)

[Stackoverflow: What's a good way to collect logs from Amazon EC2 instances?](http://stackoverflow.com/questions/1761609/whats-a-good-way-to-collect-logs-from-amazon-ec2-instances)

[How to use CloudWatch to generate alerts from logs?](https://blog.opsgenie.com/2014/08/how-to-use-cloudwatch-to-generate-alerts-from-logs)

<div class="popup">
    <div class="close">close</div>
    <div class="download"><a href="">Download (<span class="name"></span>)</a></div>
    <div class="popup-content"></div>
</div>

<style type="text/css">
</style>
<script type="text/javascript">
$(document).ready(function() {
    var popup = {
      _$link: null,

      show: function($link) {
        if (this._$link) {
          this.hide();
        }
        this._$link = $link;
        this._$link.addClass("selected");
        var self = this;
        $.get(this._$link.attr('href'), function(data) {
            $(".popup-content").html(data);
            $(".popup .download a").attr('href', self._$link.attr('href'));
            $(".popup .download a span.name").html(
                self._$link.attr('href').split('/').pop()
            );
            $(".popup").slideFadeToggle(function() {
                //can do something here
            });
        });
      },

      hide: function() {
        if (!this._$link) {
          return;
        }
        var self = this;
        $('.popup').slideFadeToggle(function() {
          self._$link.removeClass('selected');
          self._$link = null;
        });
      }
    };

    $.fn.slideFadeToggle = function(easing, callback) {
      return this.animate({ opacity: 'toggle', height: 'toggle' }, 'fast', easing, callback);
    };

    $('.close').on('click', function(e) {
      popup.hide();
      e.stopPropagation();
    });
    $('body').on('click', function(e) {
      if ($(e.target).parents('.popup').length > 0) {
        return;
      }
      popup.hide();
    });

    function isSelectable(link) {
        var href = $(link).attr('href');
        if (href && href.endsWith("config")) {
            return true;
        }
        return false;
    }
    $("a").each(function(idx, link) {
        if (isSelectable(link)) {
          $(link).addClass('selectable');
        }
    });
    $("a").click(function(event) {
        var elem = $(event.target);
        if (!isSelectable(elem)) {
            return true;
        }
        if ($(this).hasClass("selected")) {
            popup.hide();
        } else {
            popup.show($(this));
        }
        return false;
    });
});
</script>
