ARG BASE_IMAGE=ubuntu:22.04
FROM $BASE_IMAGE AS build

ENV USER="core" \
    UID=1000 \
    TZ=UTC \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    BUILD_TOOLS="wget \
                 curl \
                 gnupg \
                 software-properties-common \
                 equivs \
                 devscripts \
                 autoconf \
                 make \
                 pkg-config \
                 texinfo \
                 git \
                 gcc-10 \
                 g++-10 \
                 protobuf-compiler \
                 zlib1g-dev \
                 libxml2-dev \
                 libxft-dev \
                 libfontconfig1-dev \
                 libgnutls28-dev \
                 libx11-dev \
                 xorg-dev \
                 libcairo2-dev \
                 libgtk-3-dev" \
    EMACS_BUILD_DEPS="libgccjit-10-dev \
                      libjansson4 \
                      libm17n-0 \
                      libgif-dev \
                      libotf-dev \
                      libsqlite3-dev \
                      libtree-sitter-dev \
                      zlib1g \
                      libjansson-dev \
                      libmailutils-dev \
                      libxml2 \
                      libxft2 \
                      libfontconfig1 \
                      libgnutls30 \
                      libx11-6 \
                      libcairo2 \
                      libgtk-3-0 \
                      libharfbuzz-dev \
                      libjpeg-dev \
                      libpng-dev" \
    MOSH_BUILD_DEPS="libncurses-dev \
                     libssl-dev \
                     libprotobuf-dev"

# Install Packages
#
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install \
    sudo ncurses-term  \
    supervisor \
    openssh-server sslh haproxy \
    python3 python3-dev python3-pip python3-setuptools \
    $BUILD_TOOLS \
    $MOSH_BUILD_DEPS \
    $EMACS_BUILD_DEPS \
    -y --no-install-recommends

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1 && \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

ENV CXX=/usr/bin/g++-10 \
    CXXFLAGS="-O3 -fomit-frame-pointer" \
    CC=/usr/bin/gcc-10 \
    CFLAGS="-O3 -fomit-frame-pointer"

# Install Mosh
#
RUN git clone https://github.com/mobile-shell/mosh && \
    cd mosh && \
    ./autogen.sh && ./configure && \
    make && make install && \
    cd ../ && rm -rf mosh

# Install XPRA
#
ENV XPRA_PKGS="xpra xpra-x11 xpra-html5 dbus-x11 python3-paramiko python3-pyinotify python3-xdg python3-rencode"

RUN curl -fsSL https://xpra.org/gpg.asc | \
    sudo gpg --dearmor -o /etc/apt/keyrings/xpra-apt-keyring.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/xpra-apt-keyring.gpg] https://xpra.org/ $(lsb_release -c -s) main" | \
    tee /etc/apt/sources.list.d/xpra.list && \
    apt-get update  && \
    apt-get install $XPRA_PKGS \
    -y --no-install-recommends

RUN sed -i -e 's/\(<title>\)[^<]*\(<\/title>\)/\1emacsd\2/g' /usr/share/xpra/www/index.html && \
    sed -i -e 's/\(<title>\)[^<]*\(<\/title>\)/\1emacsd\2/g' /usr/share/xpra/www/connect.html && \
    rm -rf /usr/share/xpra/www/*.br && \
    rm -rf /usr/share/xpra/www/*.gz && \
    echo 'keyboard = false' >> /etc/xpra/html5-client/default-settings.txt && \
    echo 'floating_menu = false' >> /etc/xpra/html5-client/default-settings.txt && \
    echo 'swap_keys = no' >> /etc/xpra/html5-client/default-settings.txt

# Dufs
#
RUN ARCH="$(dpkg --print-architecture)"; \
    case "$ARCH" in \
            amd64) URL='https://github.com/sigoden/dufs/releases/download/v0.41.0/dufs-v0.41.0-x86_64-unknown-linux-musl.tar.gz' ;; \
            arm64) URL='https://github.com/sigoden/dufs/releases/download/v0.41.0/dufs-v0.41.0-aarch64-unknown-linux-musl.tar.gz' ;; \
    esac; \
    curl -L -s "${URL}" -o "dufs.tar.gz" && \
    tar -xzf dufs.tar.gz --directory=/usr/bin && \
    rm dufs.tar.gz


# Build Emacs
#
RUN git clone --depth 1 --branch emacs-29.1 https://git.savannah.gnu.org/git/emacs.git /opt/emacsd/src && \
    cd /opt/emacsd/src && \
    ./autogen.sh && \
    ./configure \
    --with-tree-sitter \
    --without-sound \
    --with-zlib \
    --with-native-compilation \
    --with-modules \
    --with-json \
    --with-mailutils \
    --with-xml2 \
    --with-sqlite3=yes \
    --with-xft \
    --with-libotf \
    --with-gnutls=yes \
    --with-x=yes \
    --with-cairo \
    --with-x-toolkit=gtk3 \
    --with-harfbuzz \
    --with-jpeg=yes \
    --with-png=yes && \
    make -j$(nproc) && \
    make install && \
    cd /opt/emacsd/ && \
    rm -rf src

# Cleanup
#
RUN apt-mark manual $EMACS_BUILD_DEPS && \
    apt-mark manual $MOSH_BUILD_DEPS && \
    apt-mark manual $XPRA_PKGS && \
    apt-get purge $BUILD_TOOLS -y && \
    apt-get autoremove -y && \
    # Fix missing libprotobuf-dev
    apt-get install libprotobuf-dev -y && \
    apt-get clean && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Setup SSHD
#
RUN mkdir /var/run/sshd && \
    chmod 0755 /var/run/sshd

# Setup Runtime
#
COPY bin/edit.sh /usr/bin/edit
RUN sudo chmod +x /usr/bin/edit

COPY conf/bashrc /root/.bashrc
COPY conf/background.png /usr/share/backgrounds/images/default.png
COPY conf/haproxy.cfg /etc/haproxy/haproxy.cfg
COPY conf/supervisord.conf /etc/supervisor/supervisord.conf
COPY bin/emacsd.sh /usr/bin/emacsd
RUN sudo chmod +x /usr/bin/emacsd
COPY bin/emacsd_client.sh /usr/bin/emacsd_client
RUN sudo chmod +x /usr/bin/emacsd_client

# Setup User
#
COPY conf/bashrc /home/$USER/.bashrc
COPY conf/bash_profile /home/$USER/.bash_profile
COPY conf/JetBrainsMono.ttf /usr/local/share/fonts/
COPY conf/emacs /home/$USER/.emacs

RUN useradd -u $UID -s /bin/bash $USER && \
    adduser $USER sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    #
    mkdir -p /home/$USER/ && \
    touch /home/$USER/.sudo_as_admin_successful && \
    touch /home/$USER/.hushlogin && \
    #
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


# Pack Image
#

FROM scratch
COPY --from=build / /

ENV USER="core"
USER $USER
WORKDIR /storage
CMD ["emacsd"]
