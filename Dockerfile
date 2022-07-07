#STM32 development tools

# target system
ARG TARGET=arm-none-eabi

# Prepare directory for tools
ARG TOOLS_PATH=/opt
ARG TOOLCHAIN_PATH=${TOOLS_PATH}/gcc-${TARGET}

# stage 1
FROM debian as stage1

# renew ARGS
ARG TARGET
ARG TOOLS_PATH
ARG TOOLCHAIN_PATH

# requested file     gcc-arm-11.2-2022.02-x86_64-arm-none-eabi.tar.xz
ARG TOOLS_ZIP=${TARGET}.tar.xz
ARG TOOLS_LINK="https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/downloads"

WORKDIR ${TOOLS_PATH}

RUN mkdir -p ${TOOLCHAIN_PATH} && \  
    apt-get update && apt-get install -y \
        wget \
        w3m \
        tar \
        xz-utils \
        bzip2 && \
    rm -rf /var/lib/apt/lists/* && \
    GCCARM_LINK="$(w3m -o display_link_number=1 -dump $TOOLS_LINK  | \
        sed -e 's/^\[[0-9]\+\] //' | \
        grep $TOOLS_ZIP | \
        grep 'x86_64'  | \
        grep 'downloads'  | \
        grep -m1 'https:' )"  && \
    wget --content-disposition -q --show-progress --progress=bar:force:noscroll -O /tmp/${TOOLS_ZIP} ${GCCARM_LINK} && \
    ls -la && \
    ls -la /tmp && \
    tar -tf /tmp/${TOOLS_ZIP} && \
    tar -xf /tmp/${TOOLS_ZIP} -C ${TOOLCHAIN_PATH} --strip-components=1
    

# stage 2
FROM alpine:latest

# user and group settings
ARG UID
ARG GID
ARG USERNAME
ARG GROUPNAME

# renew ARGS
ARG TARGET
ARG TOOLS_PATH
ARG TOOLCHAIN_PATH

WORKDIR ${TOOLS_PATH}

COPY --from=stage1 ${TOOLS_PATH} .
# Install basic programs and custom glibc
RUN mkdir -p ${TOOLCHAIN_PATH}  && \ 
    apk --update --no-cache add \
    shadow \
    python3 \
    make \
    cmake \
 #   gcc-${TARGET} \
 #   binutils-${TARGET} \
    stlink && \  
    addgroup -g $GID $GROUPNAME && \  
    adduser -u $UID -G $GROUPNAME $USERNAME && \  
    usermod --append --groups $GROUPNAME $USERNAME && \  
    usermod --shell /bin/bash $USERNAME && \ 
    # 
    ln -s ${TOOLCHAIN_PATH}/bin/* /usr/local/bin

ENV PATH ${TOOLCHAIN_PATH}/bin:$PATH
ENV CC=${TARGET}-gcc \
    CXX=${TARGET}-g++ \
    CMAKE_C_COMPILER=${TARGET}-gcc \
    CMAKE_CXX_COMPILER=${TARGET}i-g++ \
    STRIP=${TARGET}-strip \
    RANLIB=${TARGET}-ranlib \
    AS=${TARGET}-as \
    AR=${TARGET}-ar \
    LD=${TARGET}-ld \
    FC=${TARGET}-gfortran
ENV LD_LIBRARY_PATH ${TOOLCHAIN_PATH}/lib:$LD_LIBRARY_PATH

# Change workdir
WORKDIR /build

#CMD ["/bin/bash"]

USER $USERNAME