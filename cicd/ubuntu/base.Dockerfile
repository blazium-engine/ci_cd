FROM ubuntu:20.04 AS base

WORKDIR /root

ENV DOTNET_NOLOGO=true
ENV DOTNET_CLI_TELEMETRY_OPTOUT=true
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm
ENV EMSCRIPTEN_VERSION=3.1.64

RUN rm -f /etc/apt/sources.list.d/*

RUN dpkg --add-architecture i386

RUN echo "deb http://archive.ubuntu.com/ubuntu/ focal main restricted universe multiverse" > /etc/apt/sources.list && \
    echo "deb http://archive.ubuntu.com/ubuntu/ focal-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://archive.ubuntu.com/ubuntu/ focal-security main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://archive.ubuntu.com/ubuntu/ focal-backports main restricted universe multiverse" >> /etc/apt/sources.list


RUN apt-get update -y && apt-get upgrade -y

RUN apt-get install -y locales tzdata && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8


RUN ln -fs /usr/share/zoneinfo/America/Los_Angeles /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

RUN apt-get install -y --no-install-recommends \
    bash curl file gettext wget build-essential python3-pip \
    git make nano patch scons pkg-config unzip xz-utils cmake gdb \
    parallel openssl vim findutils nano ccache p7zip-full cpio \
    sed gzip tar xzip gnupg

RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -

RUN echo "deb http://apt.llvm.org/focal/ llvm-toolchain-focal main" >> /etc/apt/sources.list && \
    echo "deb-src http://apt.llvm.org/focal/ llvm-toolchain-focal main" >> /etc/apt/sources.list

RUN echo "deb http://security.ubuntu.com/ubuntu xenial-security main" >> /etc/apt/sources.list

RUN wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb

RUN apt-get update -y

RUN apt-get install -y \
    yasm \
    xvfb \
    gcc \
    g++ \
    libspeechd-dev \
    speech-dispatcher \
    fontconfig \
    dotnet-host dotnet-sdk-8.0 \
    libfontconfig-dev

RUN apt-get install -y  --no-install-recommends clang-format clang-tidy \
    clang-tools clang clangd libc++-dev libc++1 libc++abi-dev \
    libc++abi1 libclang-dev libclang1 libllvm-ocaml-dev \
    libomp-dev libomp5 lld llvm-dev llvm-runtime llvm python3-clang liblldb-20-dev lldb-20 \
    python3-lldb-20

RUN apt-get install -y \
    gcc-multilib g++-multilib \
    libc6-dev-i386 libc6-i386 \
    libc6 libc6-dev \
    libx11-dev libx11-dev:i386 \
    libxcursor-dev libxcursor-dev:i386 \
    libxinerama-dev libxinerama-dev:i386 \
    libxi-dev libxi-dev:i386 \
    libxrandr-dev libxrandr-dev:i386 \
    libgl1-mesa-dev libgl1-mesa-dev:i386 \
    libatomic-ops-dev

RUN apt-get install -y \
    libglu1-mesa-dev \
    libasound2-dev \
    libpulse-dev \
    libudev-dev \
    libwayland-dev libwayland-bin \
    libdbus-1-dev \
    libstdc++6 \
    libatomic1 \
    libfreetype6-dev \
    libssl-dev libssl1.0.0 \
    libgl-dev \
    liblzma-dev liblzma5 lzma-dev \
    libglu-dev \
    libdbus-1-dev \
    libxml2-dev  \
    bzip2 \
    libmpc-dev libmpfr-dev libgmp-dev \
    libembree-dev \
    libenet-dev \
    libfreetype-dev \
    libpng-dev \
    zlib1g-dev \
    libgraphite2-dev \
    libharfbuzz-dev \
    libogg-dev \
    libtheora-dev \
    libvorbis-dev \
    libwebp-dev \
    libmbedtls-dev \
    libminiupnpc-dev \
    libpcre2-dev \
    libzstd-dev \
    libsquish-dev \
    libicu-dev \
    libdispatch-dev \
    libltdl-dev libtool libltdl7 uuid-dev \
    gobjc gobjc++ \
    #lib32ncurses-dev lib32ncurses6 lib32ncursesw6 lib32tinfo6 lib32c-dev lib32tinfo6 libc6-i386 \
    lib64ncurses-dev lib64ncurses6 lib64ncursesw6:i386 lib64tinfo6:i386 lib64c-dev:i386 libc6-amd64:i386 lib64tinfo6:i386 \
    libncurses-dev openjdk-17-jdk


RUN apt-get install -y \
    mingw-w64 \
    mingw-w64-common \
    mingw-w64-tools \
    gcc-mingw-w64 g++-mingw-w64 directx-headers-dev 

RUN update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix && \
    update-alternatives --set x86_64-w64-mingw32-gcc /usr/bin/x86_64-w64-mingw32-gcc-posix && \
    update-alternatives --set i686-w64-mingw32-g++ /usr/bin/i686-w64-mingw32-g++-posix && \
    update-alternatives --set i686-w64-mingw32-gcc /usr/bin/i686-w64-mingw32-gcc-posix

RUN git clone --branch ${EMSCRIPTEN_VERSION} --progress https://github.com/emscripten-core/emsdk && \
    emsdk/emsdk install ${EMSCRIPTEN_VERSION} && \
    emsdk/emsdk activate ${EMSCRIPTEN_VERSION}

RUN pip install scons==4.8.0

RUN /usr/bin/x86_64-w64-mingw32-gcc-posix --version
RUN rm -rf /var/lib/apt/lists/* && \
    apt-get purge -y --auto-remove && \
    apt-get autoremove -y && \
    apt-get clean

FROM base AS godot_sdk

WORKDIR /root

ENV INSTALL_DIR /usr/local/bin

COPY cmds/install-llvm-mingw.sh $INSTALL_DIR/
RUN chmod +x $INSTALL_DIR/install-llvm-mingw.sh
RUN update-alternatives --install $INSTALL_DIR/install-llvm-mingw install-llvm-mingw $INSTALL_DIR/install-llvm-mingw.sh 10

COPY cmds/setup-osxcross.sh $INSTALL_DIR/
RUN chmod +x $INSTALL_DIR/setup-osxcross.sh
RUN update-alternatives --install $INSTALL_DIR/setup-osxcross setup-osxcross $INSTALL_DIR/setup-osxcross.sh 10

COPY cmds/setup-xcode-sdks.sh $INSTALL_DIR/
RUN chmod +x $INSTALL_DIR/setup-xcode-sdks.sh
RUN update-alternatives --install $INSTALL_DIR/setup-xcode-sdks setup-xcode-sdks $INSTALL_DIR/setup-xcode-sdks.sh 10

COPY cmds/setup-godot-sdks.sh $INSTALL_DIR/
RUN chmod +x $INSTALL_DIR/setup-godot-sdks.sh
RUN update-alternatives --install $INSTALL_DIR/setup-godot-sdks setup-godot-sdks $INSTALL_DIR/setup-godot-sdks.sh 10

COPY cmds/setup-ios-cross-toolchain.sh $INSTALL_DIR/
RUN chmod +x $INSTALL_DIR/setup-ios-cross-toolchain.sh
RUN update-alternatives --install $INSTALL_DIR/setup-ios-cross-toolchain setup-ios-cross-toolchain $INSTALL_DIR/setup-ios-cross-toolchain.sh 10

COPY cmds/setup-android-sdk.sh $INSTALL_DIR/
RUN chmod +x $INSTALL_DIR/setup-android-sdk.sh
RUN update-alternatives --install $INSTALL_DIR/setup-android-sdk setup-android-sdk $INSTALL_DIR/setup-android-sdk.sh 10

COPY cmds/install-xar.sh $INSTALL_DIR/
RUN chmod +x $INSTALL_DIR/install-xar.sh
RUN update-alternatives --install $INSTALL_DIR/install-xar install-xar $INSTALL_DIR/install-xar.sh 10

COPY cmds/download-apple-files.sh $INSTALL_DIR/
RUN chmod +x $INSTALL_DIR/download-apple-files.sh
RUN update-alternatives --install $INSTALL_DIR/download-apple-files download-apple-files $INSTALL_DIR/download-apple-files.sh 10


CMD ["/bin/bash"]
