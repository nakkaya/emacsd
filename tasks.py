"""emacsd build file."""

# docker build -f Dockerfile --tag nakkaya/emacsd:latest .
# sudo docker run -e PASSWD=1234 --rm -it -p 0.0.0.0:9191:9090 nakkaya/emacsd:latest # noqa

import os
from invoke import task
from datetime import datetime


def tag(n):
    """Create tag command."""
    t_str = datetime.now().strftime("%Y_%m_%d_%H_%M_%S")
    return ("--tag ghcr.io/nakkaya/" + n + ":latest " +
            "--tag nakkaya/" + n + ":latest " +
            "--tag nakkaya/" + n + ":" + t_str + " ")


# docker run -it --rm --privileged multiarch/qemu-user-static --credential yes --persistent yes # noqa
# docker buildx create --use --name multi-arch-builder
@task
def build(c, march=False, push=False):
    """Build Multi Arch CPU Image."""
    os.environ["BUILDKIT_PROGRESS"] = "plain"

    if march:
        cmd = "build"
        platform = " "
    else:
        cmd = "buildx build"

        if push:
            cmd = cmd + " --push"

        platform = "--platform linux/amd64,linux/arm64"

    c.run("docker " + cmd + " -f Dockerfile " + tag("emacsd") + platform + " .") # noqa
