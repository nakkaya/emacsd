#!/bin/bash

set -e

echo fs.inotify.max_user_watches=1048576 | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

if [[ -v PASSWD ]]; then
    echo $USER:$PASSWD | sudo chpasswd

    export XPRA_PASSWORD="${PASSWD}"

    htpasswd -bc /opt/emacsd/server/htpasswd $USER $PASSWD
    export RCLONE_PASSWORD="--htpasswd /opt/emacsd/server/htpasswd"

    export XPRA_ADDR="0.0.0.0:9090,auth=env"
else
    export XPRA_ADDR="0.0.0.0:9090"
    echo $USER:$USER | sudo chpasswd
    export RCLONE_PASSWORD=""
fi

if [[ -v FIX_HOME_OWNER ]]; then
    sudo chown -R $USER:$USER /home/$USER
fi

export EMACS_HOME_DIR=/storage/

if [ -f "/tmp/.X42-lock" ]; then
    rm /tmp/.X42-lock
fi


supervisord
