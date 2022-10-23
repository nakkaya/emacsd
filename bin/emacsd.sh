#!/bin/bash

set -e

#
# Init System
#
if [[ -v PASSWD ]]; then
    echo $USER:$PASSWD | sudo chpasswd

    export XPRA_PASSWORD="${PASSWD}"

    htpasswd -bc /opt/emacsd/server/htpasswd $USER $PASSWD
    export RCLONE_PASSWORD="--htpasswd /opt/emacsd/server/htpasswd"

    XPRA_ADDR="0.0.0.0:9090,auth=env"
else
    XPRA_ADDR="0.0.0.0:9090"
    echo $USER:$USER | sudo chpasswd
    export RCLONE_PASSWORD=""
fi

sudo chown -R $USER:$USER /home/$USER

export EMACS_HOME_DIR=/storage/

#
# Load User RC Files
#
source "/home/${USER}/.bashrc"

if [ -f "/storage/.bashrc" ]; then
  source /storage/.bashrc
fi

if [ -f "/home/${USER}/.bootrc" ]; then
  bash /home/$USER/.bootrc
fi

if [ -f "/storage/.bootrc" ]; then
  bash /storage/.bootrc
fi

#
# Boot Services
#
rclone serve \
       --addr :4242 \
       $RCLONE_PASSWORD \
       --dir-cache-time 5s \
       --dir-perms 0755 \
       --file-perms 0644 \
       webdav /storage &> /opt/emacsd/logs/webdav.log &

xpra \
    --socket-dir=/tmp/xprad/ \
    start :42 \
    --bind-tcp=$XPRA_ADDR \
    --html=on \
    --microphone=no \
    --pulseaudio=no \
    --speaker=no \
    --webcam=no \
    --xsettings=no \
    --clipboard=yes \
    --file-transfer=on \
    --mdns=no \
    --printing=no \
    --no-daemon \
    --start-after-connect=no \
    --start="emacs" &> /opt/emacsd/logs/xpra.log &

sudo /usr/sbin/sshd -p 2222

wait

