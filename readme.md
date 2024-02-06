# emacsd

![CI Status](https://github.com/nakkaya/emacsd/actions/workflows/main.yml/badge.svg)

A Docker image for running Emacs 29 `--with-native-compilation`. 
There is a sample `docker-compose.yml` file, that will launch a web
based interface for GUI access and SSH for TUI based access that can
be used on remote machines.

    # For Web & GUI Interface (By attaching using xpra)
    docker-compose up -d
    # then
    xpra attach tcp://127.0.0.1:9090 --window-close=disconnect
    # or
    chrome http://127.0.0.1:9090

Image runs as user `core` replace your username as required. This
image can be extended to include your development environment See
[emacs/devops/docker at master ·
nakkaya/emacs](https://github.com/nakkaya/emacs/tree/master/devops/docker)
for sample `Dockerfile`s.
