"""emacsd build file."""

from invoke import task
import subprocess
import os
import sys
import glob
sys.tracebacklimit = 0

version = subprocess.check_output(["git", "describe", "--always"])
version = version.strip().decode('UTF-8')


def tag(n):
    """Create tag command."""
    return (#"--tag nakkaya/" + n + ":latest " +
            "--tag ghcr.io/nakkaya/" + n + ":latest " #+
            #"--tag nakkaya/" + n + ":" + version + " "
            )


def run(cmd, dir="."):
    """Run cmd in dir."""
    wd = os.getcwd()
    os.chdir(dir)
    subprocess.check_call(cmd, shell=True)
    os.chdir(wd)

gpu_image = 'BASE_IMAGE=nvidia/cuda:11.2.0-cudnn8-runtime-ubuntu20.04'

@task
def build(ctx):
    """Build Images."""
    cmd = "docker build "
    #cmd = "docker build --no-cache "

    run(cmd + "-f Dockerfile " + tag("emacsd-cpu") + " .")

@task
def buildx(ctx):
    """Build Multi Arch Images."""
    cmd = "docker buildx build --push "

    run(cmd +
        " -f Dockerfile " + tag("emacsd-gpu") +
        " --platform linux/amd64 " +
        " --build-arg " + gpu_image  + " .")

    run(cmd +
        "-f Dockerfile " + tag("emacsd-cpu") +
        " --platform linux/amd64 .")
