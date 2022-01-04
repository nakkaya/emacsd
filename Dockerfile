ARG BASE_IMAGE=ubuntu:20.04
FROM $BASE_IMAGE
ENV DISTRO=focal

ENV USER="core" \
    UID=1000 \
    TZ=UTC

RUN sed -Ei 's/^# deb-src /deb-src /' /etc/apt/sources.list
RUN apt-get update && apt-get upgrade -y

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    EMACS_BUILD_TOOLS="wget \
                       gnupg \
                       software-properties-common \
                       equivs \
                       devscripts \
                       autoconf \ 
                       make \
                       pkg-config \
                       texinfo \
                       gcc-10 \
                       g++-10" \
    EMACS_BUILD_DEPS="libotf-dev \
                      libotf0 \
                      libgccjit0 \
                      libgccjit-10-dev \
                      libjansson-dev"

# Install Packages
#
RUN apt-get install \
	sudo \
	git \
	openssh-server \
	rclone \
        apache2-utils \
        python3 python3-dev python3-pip \
        $EMACS_BUILD_TOOLS \
	$EMACS_BUILD_DEPS \
	-y --no-install-recommends

# Setup User
#
COPY conf/bashrc /home/$USER/.bashrc
COPY conf/bash_profile /home/$USER/.bash_profile
COPY conf/JetBrainsMono.ttf /usr/local/share/fonts
COPY conf/emacs /home/$USER/.emacs

RUN useradd -u $UID -s /bin/bash $USER && \
    adduser $USER sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    #
    mkdir -p /home/$USER/ && \
    touch /home/$USER/.sudo_as_admin_successful && \
    #
    mkdir /opt/emacsd && \
    mkdir /run/user/$UID && \
    mkdir /run/xpra && \
    chmod 775 /run/xpra && \
    chown -R $USER:$USER /run/xpra && \
    chown -R $USER:$USER /run/user/$UID && \
    mkdir /home/$USER/.emacs.d && \
    mkdir /opt/emacsd/logs && \
    mkdir /opt/emacsd/server && \
    chown -R $USER:$USER /opt/emacsd && \
    chown -R $USER:$USER /home/$USER && \
    mkdir /storage && \
    chown -R $USER:$USER /storage

# SSH
#
RUN service ssh start

# Build Emacs
#
RUN mk-build-deps emacs \
    --install \
    --remove \
    --tool='apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends --yes' && \
    git clone --depth 1 --branch emacs-28 https://git.savannah.gnu.org/git/emacs.git /opt/emacsd/src && \
    cd /opt/emacsd/src && \
    ./autogen.sh && \
    CC=/usr/bin/gcc-10 CXX=/usr/bin/gcc-10 CFLAGS="-O3 -fomit-frame-pointer" ./configure \
    --without-all \
    --with-zlib \
    --with-native-compilation \
    --with-modules \
    --with-json \
    --with-mailutils \
    --with-xml2 \
    --with-xft \
    --with-libotf \
    --with-gnutls=yes \
    --with-x=yes \
    --with-x-toolkit=lucid \
    --with-png=yes && \
    make -j$(nproc) && \
    make install && \
    cd /opt/emacsd/ && \
    rm -rf src

# Install Python
#
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1 && \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1 && \
    pip install paramiko pyinotify xdg

# Install XPRA
#
RUN wget -q https://xpra.org/gpg.asc -O- | apt-key add - && \
    ARCH="$(dpkg --print-architecture)"; \
    case "$ARCH" in \
    amd64) add-apt-repository "deb https://xpra.org/ $DISTRO main" ;; \
    arm64) add-apt-repository "deb https://xpra.org/beta/ $DISTRO main" ;; \
    esac; \
    apt-get update && \
    apt-get install python3-rencode xpra xpra-html5 -y --no-install-recommends

RUN sed -i -e 's/\(<title>\)[^<]*\(<\/title>\)/\1emacsd\2/g' /usr/share/xpra/www/index.html && \
    sed -i -e 's/\(<title>\)[^<]*\(<\/title>\)/\1emacsd\2/g' /usr/share/xpra/www/connect.html && \
    rm -rf /usr/share/xpra/www/*.br && \
    rm -rf /usr/share/xpra/www/*.gz && \
    rm -rf /usr/share/xpra/www/default-settings.txt* && \
    touch /usr/share/xpra/www/default-settings.txt && \
    echo 'keyboard = false' >> /usr/share/xpra/www/default-settings.txt && \
    echo 'floating_menu = false' >> /usr/share/xpra/www/default-settings.txt && \
    echo 'swap_keys = no' >> /usr/share/xpra/www/default-settings.txt

RUN apt-get purge $EMACS_BUILD_TOOLS -y && \
    apt-mark manual $EMACS_BUILD_DEPS && \
    apt-get clean && \
    apt-get autoremove -y && \
    apt-get autoclean 

USER $USER

# Run
#

COPY bin/edit.sh /usr/bin/edit
RUN sudo chmod +x /usr/bin/edit

COPY bin/exec.sh /opt/emacsd/exec.sh
RUN sudo chmod +x /opt/emacsd/exec.sh

WORKDIR /home/$USER/
CMD /opt/emacsd/exec.sh
