---
title: SSH Tunnels (How to Access AWS RDS Locally Without Exposing it to Internet)
date: 2018-01-11
tags: [ssh, aws]
type: note
html: "/html/2018-01-11-aws-ec2-ssh-tunnel.html"
---

Using SSH tunnels, it is possible to access remote resources that are not exposed to the Internet through the intermediate hosts or expose your local services to the Internet.
<!-- more -->

## Setup

To make SSH commands shorter and easier to use, edit the `~/.ssh/config` and add the configuration for the hosts you are going to connect.

The configuration defines default ssh options, so instead of the command like this `ssh ec2-user@ec2-55-222-55-55.compute-1.amazonaws.com -i ~/.ssh/my_key.pem`, we can just use `ssh my-remote-host`.

An example config:

```text
Host my-remote-host
HostName ec2-55-222-55-55.compute-1.amazonaws.com
StrictHostKeyChecking no
User ec2-user
IdentityFile ~/.ssh/my_key.pem
```

## Access Remote Hidden Resource

The SSH command to access the remote hidden resource locally through the intermediate accessible host is `ssh -L`:

```bash
local_port=5532

accessible_host=my-remote-host

hidden_host=hidden_host.amazonaws.com
hidden_port=5432

ssh ${accessible_host} -L ${local_port}:${hidden_host}:${hidden_port}
```

With the command above we connect to the `my-remote-host` that has access to the `hidden_host:hidden_port` and make the hidden resource available locally:

```text
localhost:5532 =====> my-remote-host =====> hidden_host.amazonaws.com:5432
```

# Expose Local Resource To the Internet

The SSH command to expose the local resource through the intermediate host is `ssh -R`:

```bash
remote_port=8181
local_port=8888

ssh my-remote-host -R *:${remote_port}:localhost:${local_port}
```

With the command above we connect to the `my-remote-host` and instruct it to accept connections to the `8181` port and forward them to the `localhost:8888`.

The `*:8181` that remote host will forward connections to any network interface (by default it will use only 127.0.0.1).

```text
localhost:8888 <===== my-remote-host <===== my-remote-host:8181
```

You also need to make sure that firewall on `my-remote-host` allows connections to the 8181 port.


## Example: Access RDS Database Through the EC2 Instance

It is good idea to make RDS databases not available from the Internet, so they can only be accessed from the EC2 instances where applications are running.

On the other hand, during the development, it is convenient to have the database accessible from your local machine.
It is easy to do it, running the following command:

```bash
ssh my-aws-host -L 5532:my-rds-host-name.cdiofumqrcpr.us-east-1.rds.amazonaws.com:5432
```

Here `my-aws-host` is the EC2 instance that has DB access and `my-rds-host-name.cdiofumqrcpr...:5432` is the RDS host name and port.

After that, you can use the `localhost:5532` on your local machine to connect to the remote database, for example with `psql`:

```
psql postgresql://my_db_user@localhost:5432/my_db_name
```

Or dump the database with `pg_dump`:

```
pg_dump -Fc -v --dbname=postgresql://my_db_user@localhost:5432/my_db_name -f my_db_name$(date --iso-8601).pq
```

Note: both commands above don't specify the database password, to make it work, the password can be specified in the ~/.pgpass file (so it will not be present in the shell history or visible on the screen when the command is executed).

The `~/.pgpass` looks like this:

```
localhost:5432:*:my_db_user_one:XXXYYY
localhost:5432:*:my_db_user_two:XXXYYY
```

# Example: Connect to Redis on AWS

Similarly to the PostgreSQL example above, we can create an ssh tunnel to the EC2 instance that has Redis access and expose Redis locally:

```
ssh my-ec2-instance -L 6379:id.wssxxx.0001.appp1.cache.amazonaws.com:6379
```

After that, we can use `redis-cli` or any other tool on the local machine to connect to redis on 6379 port.


## Example: Expose Local Server Through the EC2 Instance

Sometimes it can be necessary to make locally running app available through the Internet.
There are several ways to do that:

- If you have the "real" IP address (you may need to ask your Internet provider to setup a real IP for you), you only need to make sure that your firewall allows connections to the port your app is running on
- Use service like http://ngrok.com which will do the forwarding from the Internet to your local machine
- Use SSH tunnel to the EC2 instance (or any other machine that's accessible from the Internet)

Let's say there is an app running locally on 8888 port (localhost:8888) and we want to make it available via the EC2 instance `ec2-55-222-55-55.compute-1.amazonaws.com:8181`.

To use the SSH tunnel, first, make sure there is a `GatewayPorts yes` option in the sshd config on the server.
Ssh to the instance, open the `/etc/sshd_config`:

```bash
sudo vim /etc/sshd_config
```

Find and change or add `GatewayPorts yes` option, save the config.
Restart sshd

```bash
sudo service sshd restart
```

Second, check and change, if necessary, the [security group configuration](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-network-security.html) for the EC2 instance and allow access to the port 8181.

Now, from your local machine run

```bash
ssh my-aws-host -R *:8181:localhost:8888
```

Now you should be able to access your local app via `ec2-55-222-55-55.compute-1.amazonaws.com:8181`.

## Troubleshooting

If the connection fails, check the following:

- ssh connection and tunnel established successfully - check the ssh output
- sometimes, the connection is working, but the tunnel isn't, in the ssh output you can see something like "Port forwarding is disabled to avoid man-in-the-middle attacks." and the instructions on what to do
- you don't have anything running locally on the specified port
  - check with `nc -v 127.0.0.1 5433` to see if there is a connection
  - additionally check with `netstat -l | grep 5433` and `lsof -i :5433`

Useful searches for other issues are "ssh tunnel aws rds problem" and "ssh tunnel aws rds connection error".

## References

[The Black Magic Of SSH / SSH Can Do That?](https://vimeo.com/54505525)

[How to make requests from an external server to localhost](https://stackoverflow.com/q/46956396/4612064)

[Connect to MongoDB on aws Server From Another Server](https://stackoverflow.com/a/44208214/4612064)
