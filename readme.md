# emacsd

![CI Status](https://github.com/nakkaya/emacsd/actions/workflows/main.yml/badge.svg)

A Docker image for running Emacs 29 `--with-native-compilation`. 

    docker run --rm -it -p 9090:9090 nakkaya/emacsd:latest

Once the container is running, you can connect to Emacs using GUI via,

    xpra attach tcp://127.0.0.1:9090 --window-close=disconnect
    # or
    chrome http://127.0.0.1:9090

or using CLI via SSH,

    ssh -p 9090 core@localhost

unless a password is specified via environment variable by default all
passwords will be the same as the default username `core`. WebDAV is
accessible via

    http://127.0.0.1:9090/disk

There is a sample `docker-compose.yml` file that has the list of
supported environment variables.

Image runs as user `core` replace your username as required. This
image can be extended to include your development environment See
[emacs/devops/docker at master ·
nakkaya/emacs](https://github.com/nakkaya/emacs/tree/master/devops/docker)
for sample `Dockerfile`s.
