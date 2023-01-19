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


def run(cmd, dir="."):
    """Run cmd in dir."""
    wd = os.getcwd()
    os.chdir(dir)
    subprocess.check_call(cmd, shell=True)
    os.chdir(wd)


def docker(builder, type, *arg):
    """Run docker command."""
    cmd = ("docker " + builder +
           " -f Dockerfile " + tag("emacsd") +
           " ".join(arg) + " .")
    run(cmd)


# sudo apt-get install -y qemu qemu-user-static
# docker buildx create --use --name multi-arch-builder
@task
def build(ctx):
    """Build Multi Arch CPU Image."""
    os.environ["BUILDKIT_PROGRESS"] = "plain"
    docker("buildx build --push", "--platform linux/amd64,linux/arm64")
    #docker("buildx build ", "--platform linux/amd64,linux/arm64")
