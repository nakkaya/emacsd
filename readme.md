# emacsd

![CI Status](https://github.com/nakkaya/emacsd/actions/workflows/main.yml/badge.svg)

A Docker image for running Emacs 28 `--with-native-compilation`. 
There is a sample `docker-compose.yml` file, that will launch a web
based interface for GUI access and SSH for TUI based access that can
be used on remote machines. If you have `python` `invoke` installed
these can be launched using,


    # For Web & GUI Interface (By attaching using xpra)
    invoke up
    # then
    xpra attach tcp://127.0.0.1:9090 --window-close=disconnect
    # or
    chrome http://127.0.0.1:9090


Image runs as user `core` replace your username as required. This
image can be extended to include your development environment See
[emacs/devops/docker at master ·
nakkaya/emacs](https://github.com/nakkaya/emacs/tree/master/devops/docker)
for sample `Dockerfile`s. There are two images with suffix `-cpu` and
`-gpu`. `-cpu` image is built from base `ubuntu:20.04`, `-gpu` is
built from `nvidia/cuda:11.2.0-cudnn8-runtime-ubuntu20.04` base image.
