FROM bioblaze/blazium-base:latest

WORKDIR /root

RUN download-project-deps

RUN install-llvm-mingw

RUN setup-android-sdk

RUN setup-godot-sdks

CMD ["/bin/bash"]