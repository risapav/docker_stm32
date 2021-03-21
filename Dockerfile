#STM32 development tools
#FROM alpine:latest
FROM frolvlad/alpine-glibc:latest

MAINTAINER Pavol Risa "risapav at gmail"

# Prepare directory for tools
ARG GCC_PATH=/opt/gcc-arm
ARG TOOLS_PATH=/tools
ARG TOOLCHAIN_PATH=${TOOLS_PATH}/toolchain
RUN mkdir -p ${TOOLCHAIN_PATH}
WORKDIR ${TOOLS_PATH}

# Install basic programs and custom glibc
RUN apk --update --no-cache add \
      python3 \
      make \
      cmake \
      stlink && \
## build dependencies
    echo "## build dependencies ##" && \
    apk --update --no-cache add --virtual build-dependencies \
      openssl \
      ca-certificates \
      wget \	
      w3m \
      tar \
      bzip2-dev && \
## get the toolchain
    echo "## get the toolchain ##" && \
    GCCARM_LINK="$(w3m -o display_link_number=1 -dump 'https://developer.arm.com/open-source/gnu-toolchain/gnu-rm/downloads' | \
      grep -m1 '^\[[0-9]\+\].*downloads.*gcc-arm-none-eabi.*linux\.tar\.bz2' | \
      sed -e 's/^\[[0-9]\+\] //')" && \	
    echo ${GCCARM_LINK} && \
    echo "Hi, I'm sleeping for 20 seconds... Please put previous URL into browser and press ENTER" && \
    sleep 20  && \	
    wget -O /tmp/gcc-arm-none-eabi.tar.bz2 ${GCCARM_LINK} && \
## unpack the archive to a neatly named target directory
    mkdir -p ${GCC_PATH} && \
    tar xjfv /tmp/gcc-arm-none-eabi.tar.bz2 -C ${GCC_PATH} --strip-components 1 && \
## remove the archive
    rm /tmp/gcc-arm-none-eabi.tar.bz2 && \
## link to tool chain
    cd ${TOOLCHAIN_PATH} && ln -s ${GCC_PATH}/* . && \
    apk del build-dependencies

ENV PATH="${TOOLCHAIN_PATH}/bin:${GCC_PATH}/bin:${PATH}"

# Change workdir
WORKDIR /build

#CMD ["/bin/bash"]
