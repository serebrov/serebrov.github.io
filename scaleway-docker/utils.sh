#!/usr/bin/env bash
set -e

SCRIPT_PATH=`dirname $0`

# An error exit function
error_exit() {
    echo "$1" 1>&2
    exit 1
}


docker_rm_app_image() {
  local APP_NAME=$1
  if docker inspect --format='{{.Id}}' $APP_NAME; then
    echo "Found image for ${APP_NAME}, stop / remove it"
    docker stop $APP_NAME
    docker rm $APP_NAME
  else
    echo "No image yet for {$APP_NAME}"
  fi
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
    if ! sudo cp $source $target; then
        error_exit "Can not copy ${source} to ${target}"
    fi
    if ! sudo chmod -R $permission $target; then
        error_exit "Can not do chmod ${permission} for ${target}"
    fi
    if ! sudo chown $user:$group $target; then
        error_exit "Can not do chown ${user}:${group} for ${target}"
    fi
    echo "cp_ext: ${source} -> ${target} chmod ${permission} & chown ${user}:${group}"
}

script_add_line() {
    local target_file=$1
    local check_text=$2
    local add_text=$3

    if grep -q "$check_text" "$target_file"
    then
        echo "Modification ${check_text} found in ${target_file}"
    else
        sudo echo ${add_text} >> ${target_file}
        echo "Modification ${add_text} added to ${target_file}"
    fi
}

set_ini_param() {
    #cp + chmod + chown
    local name=$1
    local value=$2
    local ini_file=$3
    sed -i "s/^$name=.*$/$name=$value/g" $ini_file
    echo "set_ini_param: ${name}=${value} in $ini_file"
}

install_cron() {
  local cronfile=$1
  local unique_string=$2
  # Remove any existing entries and add new ones
  crontab -l | grep -v $unique_string | { cat; cat $cronfile; } | crontab -
  echo "Crontab setup: installed file ${cronfile}"
}

#Example: create_link_if_not_exists ../../api/www application/root/api
create_link_if_not_exists() {
  local src=$1
  local link=$2
  if [[ ! -L $link ]]; then
    ln -s $src $link
  fi
}
