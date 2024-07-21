#!/bin/bash

set -e

# Check for existence of SSH host keys
host_keys_exists=$(ls /etc/ssh/ssh_host_*_key 2> /dev/null | wc -l)

# If no keys found, generate them
if [ "$host_keys_exists" -eq 0 ]; then
    ssh-keygen -A
fi

if [ ! -f "/etc/ssh/sshd_config" ]; then
    cat > "/etc/ssh/sshd_config" << 'EOF'
Port 22
PermitRootLogin no
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF
fi

if [ ! -f "/home/$USER/.bashrc" ]; then
    sudo cp /root/.bashrc "$HOME/.bashrc"
    sudo chown $(whoami):$(whoami) "$HOME/.bashrc"
    sudo chmod 644 "$HOME/.bashrc"
fi

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

set -o allexport
source /etc/environment
set +o allexport

supervisord
