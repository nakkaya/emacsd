"""emacsd build file."""

import os
from invoke import task
import subprocess
import multiprocessing
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


def docker(builder, *arg):
    """Run docker command."""
    cmd = ("docker " + builder +
           " -f Dockerfile " + tag("emacsd") +
           " ".join(arg) + " .")
    run(cmd)


# docker run -it --rm --privileged multiarch/qemu-user-static --credential yes --persistent yes # noqa
# docker buildx create --use --name multi-arch-builder
@task
def build(ctx, push=False):
    """Build Multi Arch CPU Image."""
    os.environ["BUILDKIT_PROGRESS"] = "plain"

    cmd = "buildx build"
    if push:
        cmd = cmd + " --push"

    docker(cmd,
           "--platform linux/amd64,linux/arm64",
           " --build-arg N_CPU=" + str(multiprocessing.cpu_count()))
