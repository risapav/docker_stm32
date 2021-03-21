#STM32 development tools
#FROM alpine:latest
FROM frolvlad/alpine-glibc:latest

MAINTAINER Pavol Risa "risapav at gmail"

# Prepare directory for tools
ARG TOOLS_PATH=/tools
ARG TOOLCHAIN_PATH=${TOOLS_PATH}/toolchain
RUN mkdir ${TOOLS_PATH}
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
	echo "Hi, I'm sleeping for 30 seconds... Please put previous URL into browser and press ENTER" && \
	sleep 30  && \	
	wget -O /tmp/gcc-arm-none-eabi.tar.bz2 ${GCCARM_LINK} && \
# unpack the archive to a neatly named target directory
	mkdir gcc-arm-none-eabi && \
	tar xjfv /tmp/gcc-arm-none-eabi.tar.bz2 -C gcc-arm-none-eabi --strip-components 1 && \
# remove the archive
	rm /tmp/gcc-arm-none-eabi.tar.bz2 && \
#	wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
#	wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.33-r0/glibc-2.33-r0.apk && \
#	apk add glibc-2.33-r0.apk	&& \
#    rm -rf /usr/local/share/doc && \
	apk del build-dependencies

#apk --no-cache add ca-certificates wget make cmake stlink gcc-arm-none-eabi \
#	&& wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
#	&& wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.33-r0/glibc-2.33-r0.apk \
#	&& apk add glibc-2.33-r0.apk

ENV PATH="${TOOLCHAIN_PATH}/bin:${PATH}"

# Change workdir
WORKDIR /build

#CMD ["/bin/bash"]
