"""emacsd build file."""

import os
from invoke import task
import subprocess
from datetime import datetime


def tag(n):
    """Create tag command."""
    t_str = datetime.now().strftime("%Y_%m_%d_%H_%M_%S")
    return ("--tag ghcr.io/nakkaya/" + n + ":latest " +
            "--tag nakkaya/" + n + ":latest " +
            "--tag nakkaya/" + n + ":" + t_str + " ")


gpu_image = 'BASE_IMAGE=nvidia/cuda:11.6.0-cudnn8-runtime-ubuntu20.04'


def run(cmd, dir="."):
    """Run cmd in dir."""
    wd = os.getcwd()
    os.chdir(dir)
    subprocess.check_call(cmd, shell=True)
    os.chdir(wd)


def docker(builder, type, *arg):
    """Run docker command."""
    cmd = ("docker " + builder +
           " -f Dockerfile " + tag("emacsd-" + type) +
           " ".join(arg) + " .")
    run(cmd)


@task
def build_cpu(ctx):
    """Build CPU Image."""
    docker("build", "cpu")


@task
def build_gpu(ctx):
    """Build GPU Image."""
    docker("build", "gpu", "--build-arg", gpu_image)
    run("docker push --all-tags nakkaya/emacsd-gpu")
    run("docker push --all-tags ghcr.io/nakkaya/emacsd-gpu")


@task
def buildx_cpu(ctx):
    """Build Multi Arch CPU Image."""
    docker("buildx build --push", "cpu", "--platform linux/amd64,linux/arm64")
