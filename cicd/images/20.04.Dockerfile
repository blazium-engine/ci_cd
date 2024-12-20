FROM ubuntu:20.04 AS base

WORKDIR /root

ENV DOTNET_NOLOGO=true
ENV DOTNET_CLI_TELEMETRY_OPTOUT=true
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm

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
    libssl-dev \
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
    libicu-dev


RUN apt-get install -y \
    mingw-w64 \
    mingw-w64-common \
    mingw-w64-tools \
    gcc-mingw-w64 g++-mingw-w64 directx-headers-dev

RUN update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix && \
    update-alternatives --set x86_64-w64-mingw32-gcc /usr/bin/x86_64-w64-mingw32-gcc-posix && \
    update-alternatives --set i686-w64-mingw32-g++ /usr/bin/i686-w64-mingw32-g++-posix && \
    update-alternatives --set i686-w64-mingw32-gcc /usr/bin/i686-w64-mingw32-gcc-posix

RUN /usr/bin/x86_64-w64-mingw32-gcc-posix --version
RUN rm -rf /var/lib/apt/lists/* && \
    apt-get purge -y --auto-remove && \
    apt-get autoremove -y && \
    apt-get clean

FROM base AS godot_sdk

WORKDIR /root

ENV OSXCROSS_ROOT="/root/deps/osxcross"

RUN mkdir -p deps/llvm-mingw && \
    curl -LO https://github.com/mstorsjo/llvm-mingw/releases/download/20240619/llvm-mingw-20240619-ucrt-ubuntu-20.04-x86_64.tar.xz && \
    tar xf llvm-mingw-20240619-ucrt-ubuntu-20.04-x86_64.tar.xz && \
    rm -f llvm-mingw-20240619-ucrt-ubuntu-20.04-x86_64.tar.xz && \
    mv -f llvm-mingw-20240619-ucrt-ubuntu-20.04-x86_64 /root/deps/llvm-mingw


RUN mkdir -p deps/swappy && \
    cd deps/swappy && \
    curl -L -O https://github.com/darksylinc/godot-swappy/releases/download/v2023.3.0.0/godot-swappy.7z && \
    7z x godot-swappy.7z && \
    rm godot-swappy.7z

RUN mkdir -p deps/mesa && \
    cd deps/mesa && \
    curl -L -o mesa_arm64.zip https://github.com/godotengine/godot-nir-static/releases/download/23.1.9-1/godot-nir-static-arm64-llvm-release.zip && \
    curl -L -o mesa_x86_64.zip https://github.com/godotengine/godot-nir-static/releases/download/23.1.9-1/godot-nir-static-x86_64-gcc-release.zip && \
    curl -L -o mesa_x86_32.zip https://github.com/godotengine/godot-nir-static/releases/download/23.1.9-1/godot-nir-static-x86_32-gcc-release.zip && \
    unzip -o mesa_arm64.zip && rm -f mesa_arm64.zip && \
    unzip -o mesa_x86_64.zip && rm -f mesa_x86_64.zip && \
    unzip -o mesa_x86_32.zip && rm -f mesa_x86_32.zip

RUN mkdir -p deps/angle && \
    cd deps/angle && \
    base_url=https://github.com/godotengine/godot-angle-static/releases/download/chromium%2F6601.2/godot-angle-static && \
    curl -L -o windows_arm64.zip $base_url-arm64-llvm-release.zip && \
    curl -L -o windows_x86_64.zip $base_url-x86_64-gcc-release.zip && \
    curl -L -o windows_x86_32.zip $base_url-x86_32-gcc-release.zip && \
    curl -L -o macos_arm64.zip $base_url-arm64-macos-release.zip && \
    curl -L -o macos_x86_64.zip $base_url-x86_64-macos-release.zip && \
    unzip -o windows_arm64.zip && rm -f windows_arm64.zip && \
    unzip -o windows_x86_64.zip && rm -f windows_x86_64.zip && \
    unzip -o windows_x86_32.zip && rm -f windows_x86_32.zip && \
    unzip -o macos_arm64.zip && rm -f macos_arm64.zip && \
    unzip -o macos_x86_64.zip && rm -f macos_x86_64.zip

RUN mkdir -p deps/moltenvk && \
    cd deps/moltenvk && \
    curl -L -o moltenvk.tar https://github.com/godotengine/moltenvk-osxcross/releases/download/vulkan-sdk-1.3.283.0-2/MoltenVK-all.tar && \
    tar xf moltenvk.tar && rm -f moltenvk.tar && \
    mv MoltenVK/MoltenVK/include/ MoltenVK/ && \
    mv MoltenVK/MoltenVK/static/MoltenVK.xcframework/ MoltenVK/


CMD ["/bin/bash"]
