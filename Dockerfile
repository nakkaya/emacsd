ARG BASE_IMAGE=ubuntu:22.04
FROM $BASE_IMAGE as build

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
                       g++-10 \
                       libgccjit-10-dev \
                       libsqlite3-dev" \
    EMACS_BUILD_DEPS="libgccjit0 \
                      libjansson4 \
                      libm17n-0 \
                      libgif7 \
                      libotf1 \
                      libsqlite3-0"

# Install Packages
#
RUN apt-get install \
    supervisor \
    sudo \
    git \
    openssh-server \
    rclone \
    apache2-utils \
    python3 python3-dev python3-pip python3-setuptools \
    python3-paramiko python3-pyinotify python3-xdg python3-rencode \
    ncurses-term \
    $EMACS_BUILD_TOOLS \
    $EMACS_BUILD_DEPS \
    -y --no-install-recommends

ENV CXX=/usr/bin/g++-10 \
    CXXFLAGS="-O3 -fomit-frame-pointer" \
    CC=/usr/bin/gcc-10 \
    CFLAGS="-O3 -fomit-frame-pointer"

# Install Mosh
#
RUN apt-get install \
    protobuf-compiler libprotobuf-dev \
    libncurses5-dev \
    libssl-dev \
    -y --no-install-recommends && \
    git clone https://github.com/mobile-shell/mosh && \
    cd mosh && \
    ./autogen.sh && ./configure && \
    make && make install && \
    cd ../ && rm -rf mosh

# Install Python
#
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1 && \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

# Install XPRA
#
RUN curl -fsSL https://xpra.org/gpg.asc | \
    sudo gpg --dearmor -o /etc/apt/keyrings/xpra-apt-keyring.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/xpra-apt-keyring.gpg] https://xpra.org/ $(lsb_release -c -s) main" | \
    tee /etc/apt/sources.list.d/xpra.list && \
    apt-get update  && \
    apt-get install xpra xpra-x11 xpra-html5 \
    -y --no-install-recommends   && \
    apt-mark hold xpra xpra-x11 xpra-html5

RUN sed -i -e 's/\(<title>\)[^<]*\(<\/title>\)/\1emacsd\2/g' /usr/share/xpra/www/index.html && \
    sed -i -e 's/\(<title>\)[^<]*\(<\/title>\)/\1emacsd\2/g' /usr/share/xpra/www/connect.html && \
    rm -rf /usr/share/xpra/www/*.br && \
    rm -rf /usr/share/xpra/www/*.gz && \
    echo 'keyboard = false' >> /etc/xpra/html5-client/default-settings.txt && \
    echo 'floating_menu = false' >> /etc/xpra/html5-client/default-settings.txt && \
    echo 'swap_keys = no' >> /etc/xpra/html5-client/default-settings.txt

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
    git clone --depth 1 --branch emacs-29.1 https://git.savannah.gnu.org/git/emacs.git /opt/emacsd/src && \
    cd /opt/emacsd/src && \
    ./autogen.sh && \
    ./configure \
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


RUN apt-get purge $EMACS_BUILD_TOOLS -y && \
    apt-mark manual $EMACS_BUILD_DEPS && \
    apt-get autoremove -y && \
    apt-get clean && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Run
#

COPY bin/edit.sh /usr/bin/edit
RUN sudo chmod +x /usr/bin/edit

COPY conf/supervisord.conf /etc/supervisor/supervisord.conf
COPY bin/emacsd.sh /usr/bin/emacsd
RUN sudo chmod +x /usr/bin/emacsd
COPY bin/emacsd_client.sh /usr/bin/emacsd_client
RUN sudo chmod +x /usr/bin/emacsd_client

# Pack Image
#

FROM scratch
COPY --from=build / /

ENV USER="core"
USER $USER
WORKDIR /storage
CMD ["emacsd"]
