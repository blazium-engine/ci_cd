# Use Ubuntu 16.04 32-bit image
FROM i386/ubuntu:16.04

# Set environment variables for non-interactive installations
ENV DEBIAN_FRONTEND=noninteractive

# Enable support for 32-bit (i386) architecture, 
#       allowing installation of 32-bit libraries
RUN dpkg --add-architecture i386 

RUN apt-get update

# Update package list and install essential packages
RUN apt-get install -y --no-install-recommends \
        build-essential \
        gcc-multilib \
        g++-multilib \
        curl \
        git \
        vim \
        tzdata \        
        file \
        findutils \
        make \
        nano \
        patch \
        unzip \
        cmake \
        gdb \
        ccache \
        yasm 

# Install packages needed for buildroot
RUN apt-get install -y \
        wget \
        cpio \
        rsync \
        bc \
        diffutils \
        perl:i386 \
        cmake-curses-gui \
        libtbb-dev \
        libglfw3-dev 


# Install additional development dependencies (i386 specific)
RUN apt-get install -y \
        scons:i386 \
        libc6:i386 \ 
        libstdc++6:i386 \
        libz1:i386 \
        pkg-config:i386 \
        libx11-dev:i386 \
        libxcursor-dev:i386 \
        libxinerama-dev:i386 \
        libgl1-mesa-dev:i386 \
        libglu1-mesa-dev:i386 \
        libasound2-dev:i386 \
        libpulse-dev:i386 \
        libudev-dev:i386 \
        libxi-dev:i386 \
        libxrandr-dev:i386 \
        libwayland-dev:i386 \
        mesa-vulkan-drivers:i386 \
        xz-utils:i386 \
        libssl-dev:i386 \
        gettext:i386 \
        bzip2:i386 \
        zlib1g-dev:i386 

RUN apt-get install -y \
        libenet-dev:i386 \
        libfreetype6-dev:i386 \
        libpng-dev:i386 \
        zlib1g-dev:i386 \
        libgraphite2-dev:i386 \
        libharfbuzz-dev:i386 \
        libogg-dev:i386 \
        libtheora-dev:i386 \
        libvorbis-dev:i386 \
        libwebp-dev:i386 \
        libmbedtls-dev:i386 \
        libminiupnpc-dev:i386 \
        libpcre2-dev:i386 \
        libzstd-dev:i386 \
        libicu-dev:i386

# Install other necessary packages
RUN apt-get install -y \
            openssl \
            parallel 

# Optional: Set locale
RUN apt-get install -y locales && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8

# Set timezone to Los Angeles
RUN ln -fs /usr/share/zoneinfo/America/Los_Angeles /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /root

# Entry point (can be modified as needed)
CMD ["/bin/bash"]
