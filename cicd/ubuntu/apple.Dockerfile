FROM bioblaze/blazium-base:latest

WORKDIR /root

RUN download-apple-files

RUN download-project-deps

RUN install-llvm-mingw

RUN install-xar test

RUN setup-xcode-sdks

RUN setup-osxcross

RUN setup-ios-cross-toolchain

CMD ["/bin/bash"]