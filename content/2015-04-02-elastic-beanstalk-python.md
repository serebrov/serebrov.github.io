---
title: Elastic Beanstalk - python application server structure and celery installation
date: 2015-04-02
tags: [aws, eb, python, celery, zeromq]
type: note
---

Elastic beanstalk python application is deployed under `/opt/python/`.
The application is running under Apache web server.
<!-- more -->

Source folder structure is this:

```
bin
  httpdlaunch - a tool script to set environment variables and launch httpd
bundle        - dir with app source code, used during updates
current       - symlink to the recent source code version under bundle
  app         - application sources
  env         - shell script with environment variables (passed from EB environment settings)
etc           - supervisord config
log           - supervisord logs
run           - virtual environments
```

Apache logs, deployment logs and system messages log are under `/var/log`.

Another important directory is `/opt/elasticbeanstalk` - here there are EB tool scripts and app server restart hooks.

Apache is managed by [supervisord](http://supervisord.org/), to check the status run this command:

```bash
sudo /usr/local/bin/supervisorctl -c /opt/python/etc/supervisord.conf status
```

And you can restart apache like this:

```bash
sudo /usr/local/bin/supervisorctl -c /opt/python/etc/supervisord.conf restart httpd
```

### How to launch python application manually

I have a [flask](http://flask.pocoo.org/) application and usually it is started as `python application.py`.
To run it on the server instance you need to init virtual environment and set environment variables first:

```bash
source /opt/python/run/venv/bin/activate && source /opt/python/current/env
```

Now you can start the application manually:

```bash
cd /opt/python/current/app
python application.py
```

Or start flask shell with `flask shell`.

### How to install celery

[Celery](http://www.celeryproject.org/) is a distributed task queue.

Our requirements are following:

- the celery application should be launched automatically when new version is deployed to Elastic Beanstalk
- the celery application should be watched by supervisord and restarted in the case of failure

The final project structure will be this:

```
  .ebextensions/               - elastic beanstal configs
    myapp.config               - main config
    deploy.sh                  - deployment script, launched from main config
    utils.sh                   - utility functions for deployment script
    files/
      celeryd.conf             - celery app config for supervisord
      99_restart_services.sh   - app server restart / reload hook
  scripts/
    celeryd                    - script to run celery application
  celery.py                    - celery application
  application.py               - main application
  requirements.txt             - project requirements for pip
```

First, add the following line to the requirements.txt in the root folder of your project (these requirements will be installed with pip automatically):

```
...
Celery==3.1.17
```

Note that the version number can be different, 3.1.17 is just an actual version at the moment of writing.

Then create a main celery application file. In my case, this is `celery.py` file in the root folder.
Here I don't describe the celery application file content - do whatever you need from celery here.

Now modify the elasticbeanstalk config (.elasticbeanstak/myapp.config) to include the deployment script:

```bash
container_commands:
  004-start-container-commands:
    command: logger "Start deploy script" -t "DEPLOY"
  005-command:
    command: chmod +x .ebextensions/deploy.sh
  006-deploy:
    command: .ebextensions/deploy.sh 2>&1 | /usr/bin/logger -t "DEPLOY" ; test ${PIPESTATUS[0]} -eq 0
  200-end-container-commands:
    command: logger "End container commands" -t "DEPLOY"
```

Here we configure ElasticBeanstalk to launch the custom deployment script.

In general I find the approach with shell script for beanstalk configuration to be much more convenient than the standard way to put shell script code to the text config file.
More details about this method can be found in the great [Innocuous looking Evil Devil](http://www.hudku.com/blog/innocuous-looking-evil-devil/) article. Check also [related posts](http://www.hudku.com/blog/tag/elastic-beanstalk).

This deployment script `.ebextensions/deploy.sh`:

```bash
#!/usr/bin/env bash
set -e

SCRIPT_PATH=`dirname $0`

source $SCRIPT_PATH/utils.sh
# Check for leader: see utils.sh
if is_leader; then
  echo "Start leader deploy"
else
  echo "Start non-leader deploy"
fi

# copy celery app config
copy_ext $SCRIPT_PATH/files/celeryd.conf /opt/python/etc/celeryd.conf 0755 root root
# copy restart hook to different hooks folders
copy_ext $SCRIPT_PATH/files/99_restart_services.sh /opt/elasticbeanstalk/hooks/appdeploy/enact/99_restart_services.sh 0755 root root
copy_ext $SCRIPT_PATH/files/99_restart_services.sh /opt/elasticbeanstalk/hooks/configdeploy/enact/99_restart_services.sh 0755 root root
copy_ext $SCRIPT_PATH/files/99_restart_services.sh /opt/elasticbeanstalk/hooks/restartappserver/enact/99_restart_services.sh 0755 root root

# include celeryd.conf into the supervisord.conf
script_add_line /opt/python/etc/supervisord.conf "include" "[include]"
script_add_line /opt/python/etc/supervisord.conf "celeryd.conf" "files=celeryd.conf "

# Reread the supervisord config
supervisorctl -c /opt/python/etc/supervisord.conf reread
# Update supervisord in cache without restarting all services
supervisorctl -c /opt/python/etc/supervisord.conf update
# Start/Restart celeryd through supervisord
supervisorctl -c /opt/python/etc/supervisord.conf restart celeryd
```

A small inconvenience with supervisord is that configuration for all apps managed by supervisord should be inside the main supervisord.conf file or additional configs should be included into it.
So in any case we need to modify the main supervisord config.
The script above does this by adding a following lines to it:

```
[include]
; it is possible to include multiple files, names should be separated by space
files=celeryd.conf
```

The `celeryd.conf` is copied into the same folder where supervisord.conf resides.

The `.ebextensions/utils.sh` script contains additional functions used by deployment script:

```bash
#!/usr/bin/env bash
set -e

SCRIPT_PATH=`dirname $0`

# An error exit function
error_exit() {
    echo "$1" 1>&2
    exit 1
}

# Copy + chmod + chown
# copy_ext source target 0755 user:group
copy_ext() {
    #cp + chmod + chown
    local source=$1
    local target=$2
    local permission=$3
    local user=$4
    local group=$5
    if ! cp $source $target; then
        error_exit "Can not copy ${source} to ${target}"
    fi
    if ! chmod -R $permission $target; then
        error_exit "Can not do chmod ${permission} for ${target}"
    fi
    if ! chown $user:$group $target; then
        error_exit "Can not do chown ${user}:${group} for ${target}"
    fi
    echo "cp_ext: ${source} -> ${target} chmod ${permission} & chown ${user}:${group}"
}

is_leader() {
    # Check for leader: /opt/elasticbeanstalk/bin/leader-test.sh:
    # use as
    # if is_leader; then
    #    dosmth
    # else
    #    doelse
    # fi
    if [[ "$EB_IS_COMMAND_LEADER" == "true" ]]; then
        # to be used in if's, so '0' means true (like for script exit code - 0 is success)
        #return 0
        #more clear (true returns 0)
        true
    else
        # to be used in if's, so '1' means false
        #return 1
        #more clear (false returns non zero)
        false
    fi
}

script_add_line() {
    local target_file=$1
    local check_text=$2
    local add_text=$3

    if grep -q "$check_text" "$target_file"
    then
        echo "Modification ${check_text} found in ${target_file}"
    else
        echo ${add_text} >> ${target_file}
        echo "Modification ${add_text} added to ${target_file}"
    fi
}
```

The celeryd.conf in `.ebextensions/files/celeryd.conf` is a supervisord config:

```ini
[program:celeryd]
command=/opt/python/current/app/scripts/celeryd

directory=/opt/python/current/app
user=wsgi
numprocs=1
stdout_logfile=/opt/python/log/celery-worker.log
stderr_logfile=/opt/python/log/celery-worker.log
autostart=true
autorestart=true
startsecs=10

; Need to wait for currently executing tasks to finish at shutdown.
; Increase this if you have very long running tasks.
stopwaitsecs = 60

; When resorting to send SIGKILL to the program to terminate it
; send SIGKILL to its whole process group instead,
; taking care of its children as well.
killasgroup=true

; if rabbitmq is supervised, set its priority higher
; so it starts first
; priority=998
```

Restart hook `.ebextensions/files/99_restart_services.sh` restarts celery application when application server is reloaded or restarted:

```bash
#!/bin/bash

set -xe

# check if we already have the celeryd service
/usr/bin/supervisorctl -c /opt/python/etc/supervisord.conf status | grep celeryd
if [[ $? ]]; then
  /usr/bin/supervisorctl -c /opt/python/etc/supervisord.conf restart celeryd
fi

eventHelper.py --msg "Application server successfully restarted." --severity INFO
```

Finally the script under `scripts/celeryd` is used to set environment variables, activate virtual environment and run celery application:

```bash
#!/bin/bash

source /opt/python/current/env
source /opt/python/run/venv/bin/activate
cd /opt/python/current/app
# Note: exec is important here - this way supervisord will control
# the python script and not the bash script
# See also: http://sortedaffairs.tumblr.com/post/49113594655/managing-virtualenv-apps-with-supervisor
#
exec /opt/python/run/venv/bin/celery worker -A tasks --loglevel=INFO
```

Actually we configured Elastic Beanstalk to run and manage an additional application.
The same approach can be used for any kind of application, not necessary celery - it can be any other application even written in other than python language.

### Bonus: how to install ZeroMQ libaray

To install ZeroMQ python library add it to requirements.txt:

```
Flask==0.9
boto==2.34.0
...
pyzmq==13.0.2
```

Installation process also includes a compilation phase and you can get an error like this:

```
gcc: error trying to exec 'cc1plus': execvp: No such file or directory
```

To solve this problem, add following packages into the elasticbeanstalk config:

```yaml
  packages:
    yum:
      gcc: []
      gcc-c++: []
```
