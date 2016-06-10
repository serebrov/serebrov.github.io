#!/usr/bin/env bash

# Run this once to register the scaleway host
# it will install docker automatically
#
# It is also necessary to open the 2375 port in the security group
# 
# If something goes wrong during the setup, run
# `docker-machine rm scaleway` and try again

SSH_HOST=163.172.131.19
SSH_USER=root
SSH_KEY=~/.ssh/id_rsa_scaleway

# For some reason the docker installation fails to run on scaleway
# the error is
#   There are no more loopback devices available.
#   [graphdriver] prior storage driver \"devicemapper\" failed: loopback attach failed
# it happens even if we specify different storage driver (overlay)
# See http://carlo-colombo.github.io/2016/05/14/Using-Docker-Cloud-on-Scaleway-vps/
#
# To fix it, run the following script first
ssh -t $SSH_USER@$SSH_HOST -i $SSH_KEY << EOF
  for i in \$(seq 0 255); do
    if [ ! -e /dev/loop\$i ]; then
      mknod -m0660 /dev/loop\$i b 7 \$i
      chown root.disk /dev/loop\$i
    fi
  done
EOF
echo 'Created loopback devices'

docker-machine create --driver generic \
 --generic-ip-address $SSH_HOST \
 --generic-ssh-user $SSH_USER \
 --generic-ssh-key $SSH_KEY \
 --engine-storage-driver overlay \
 scaleway
