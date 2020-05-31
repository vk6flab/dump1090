# This Dockerfile purposefully uses single line commands to create the image to
# allow the cache to work as much as possible during the process of determining
# build requirements.

# Use a 32-bit distribution of Debian
FROM i386/debian:stretch-slim AS pluto-compiler
LABEL maintainer="cq@vk6flab.com"

# Get the bits needed to compile things
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install busybox git build-essential wget
RUN busybox --install

WORKDIR /usr/local/bin

# Get the compiler as described here: https://wiki.analog.com/university/tools/pluto/devs/embedded_code
RUN wget -q http://releases.linaro.org/components/toolchain/binaries/7.2-2017.11/arm-linux-gnueabihf/gcc-linaro-7.2.1-2017.11-i686_arm-linux-gnueabihf.tar.xz
RUN tar -xf gcc-linaro-7.2.1-2017.11-i686_arm-linux-gnueabihf.tar.xz

ENV PATH=${PATH}:/usr/local/bin/gcc-linaro-7.2.1-2017.11-i686_arm-linux-gnueabihf/bin
ENV CC=arm-linux-gnueabihf-gcc
ENV HOST=arm-linux-gnueabihf

# Prove that it works
RUN arm-linux-gnueabihf-gcc --version

# Update this section to compile other source code
FROM pluto-compiler AS pluto-dump1090

RUN mkdir /plutosdr
WORKDIR /plutosdr

# Make sure that the version number for your firmware matches this sysroot URL.
RUN wget -q https://github.com/analogdevicesinc/plutosdr-fw/releases/download/v0.31/sysroot-v0.31.tar.gz
RUN tar -zxf sysroot-v0.31.tar.gz

# Add the compiler bits to our sysroot
RUN tar -xf /usr/local/bin/gcc-linaro-7.2.1-2017.11-i686_arm-linux-gnueabihf.tar.xz  --directory staging

# Get the source we're actually building
RUN git clone https://github.com/vk6flab/dump1090.git

WORKDIR /plutosdr/dump1090

RUN CFLAGS=--sysroot=../staging LDFLAGS=--sysroot=../staging make

# Show the md5sum so we can compare builds
RUN md5sum dump1090
