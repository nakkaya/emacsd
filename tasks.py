"""emacsd build file."""

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
def build(ctx, push=False):
    """Build Multi Arch CPU Image."""
    os.environ["BUILDKIT_PROGRESS"] = "plain"

    cmd = "buildx build"

    if push:
        cmd = cmd + " --push"

    cmd = ("docker " + cmd +
           " -f Dockerfile " + tag("emacsd") +
           "--platform linux/amd64,linux/arm64" + " .")

    ctx.run(cmd)
