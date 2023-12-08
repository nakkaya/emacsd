#!/bin/bash

echo -e "\033]0;emacsd@`hostname`\a"
SSH_TTY=`tty` emacsclient -s /opt/emacsd/server/emacsd --tty
