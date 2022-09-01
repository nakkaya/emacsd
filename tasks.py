"""emacsd build file."""

from invoke import task
import subprocess


def tag(n):
    """Create tag command."""
    return ("--tag ghcr.io/nakkaya/" + n + ":latest ")


gpu_image = 'BASE_IMAGE=nvidia/cuda:11.4.0-cudnn8-runtime-ubuntu20.04'


def docker(builder, type, *arg):
    """Run docker command."""
    cmd = ("docker " + builder +
           " -f Dockerfile " + tag("emacsd-" + type) +
           " ".join(arg) + " .")
    subprocess.check_call(cmd, shell=True)


@task
def build_cpu(ctx):
    """Build CPU Image."""
    docker("build", "cpu")


@task
def build_gpu(ctx):
    """Build GPU Image."""
    docker("build", "gpu", "--build-arg", gpu_image)


@task
def buildx_cpu(ctx):
    """Build Multi Arch CPU Image."""
    docker("buildx build --push", "cpu", "--platform linux/amd64,linux/arm64")
