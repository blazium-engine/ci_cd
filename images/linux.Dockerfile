FROM fedora:40 AS base

WORKDIR /root

ENV DOTNET_NOLOGO=1
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV SCON_VERSION=4.8.0

RUN dnf update -y

# Install bash, curl, and other basic utilities
RUN dnf install -y \
    bash bzip2 curl file findutils gettext git make nano patch pkg-config unzip xz \
    && dnf clean all

# Install Python and pip for SCons
RUN dnf install -y python3-pip \
    && dnf clean all

# Install SCons
RUN pip install scons==${SCON_VERSION}

# Install .NET SDK
RUN dnf install -y dotnet-sdk-8.0 \
    && dnf clean all

# Install Wayland development tools
RUN dnf install -y wayland-devel \
    && dnf clean all

# Stage 2: Godot SDK setup
FROM base AS godot_sdk

WORKDIR /root

ENV GODOT_SDK_VERSIONS="x86_64 i686 aarch64 arm"
ENV GODOT_SDK_BASE_URL="https://downloads.tuxfamily.org/godotengine/toolchains/linux/2024-01-17"
ENV GODOT_SDK_PATH="/root"

# Download and install Godot SDKs for various architectures
RUN for arch in $GODOT_SDK_VERSIONS; do \
      curl -LO ${GODOT_SDK_BASE_URL}/${arch}-godot-linux-gnu_sdk-buildroot.tar.bz2 && \
      tar xf ${arch}-godot-linux-gnu_sdk-buildroot.tar.bz2 && \
      rm -f ${arch}-godot-linux-gnu_sdk-buildroot.tar.bz2 && \
      cd ${arch}-godot-linux-gnu_sdk-buildroot && \
      ./relocate-sdk.sh && \
      cd /root; \
    done

CMD ["/bin/bash"]
