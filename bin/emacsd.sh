#!/bin/bash

set -e

echo fs.inotify.max_user_watches=1048576 | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

if [[ ! -v PASSWD ]]; then
    export PASSWD=$USER
fi

echo $USER:$PASSWD | sudo chpasswd
export XPRA_PASSWORD="${PASSWD}"
export WEBDAV_PASSWORD="-a ${USER}:${PASSWD}@/:rw"

export XPRA_ADDR="0.0.0.0:49156,auth=env"

sudo sed -i "/default_backend xpra/a \ \nuserlist logins\n \ user $USER insecure-password $PASSWD" /etc/haproxy/haproxy.cfg

if [[ -v FIX_HOME_OWNER ]]; then
    sudo chown -R $USER:$USER /home/$USER
fi

export EMACS_HOME_DIR=/storage/

if [ -f "/tmp/.X42-lock" ]; then
    rm /tmp/.X42-lock
fi


supervisord
