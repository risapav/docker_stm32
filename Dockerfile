#STM32 development tools

# target system
# AArch32 bare-metal target (arm-none-eabi)
ARG TARGET=arm-none-eabi

# Prepare directory for tools
ARG TOOLS_PATH=/opt
ARG TOOLCHAIN=${TOOLS_PATH}/${TARGET}

# stage 1
FROM debian:stable-slim as builder

# renew ARGS
ARG TARGET
ARG TOOLS_PATH
ARG TOOLCHAIN

# requested file     gcc-arm-11.2-2022.02-x86_64-arm-none-eabi.tar.xz
ARG TOOLS_ZIP=${TARGET}.tar.xz
ARG TOOLS_LINK="https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/downloads"

# install build tools
RUN mkdir -p ${TOOLCHAIN} \  
    && apt-get update \
    && apt-get install -y \
        wget \
        w3m \
        tar \
        xz-utils \
        bzip2 \
    && rm -rf /var/lib/apt/lists/* 

WORKDIR ${TOOLS_PATH}

# grab required toolchain
RUN GCCARM_LINK="$(w3m -o display_link_number=1 -dump $TOOLS_LINK  | \
        sed -e 's/^\[[0-9]\+\] //' | \
        grep $TOOLS_ZIP | \
        grep 'x86_64'  | \
        grep 'downloads'  | \
        grep -m1 'https:' )" \
    && wget --content-disposition -q --show-progress --progress=bar:force:noscroll -O /tmp/${TOOLS_ZIP} ${GCCARM_LINK} 

RUN tar -xvf /tmp/${TOOLS_ZIP} -C ${TOOLCHAIN} --strip-components=1
    

# stage 2
FROM debian:stable-slim as gnu-cross-toolchain

# user and group settings
ARG UID
ARG GID
ARG USERNAME
ARG GROUPNAME

# renew ARGS
ARG TARGET
ARG TOOLS_PATH
ARG TOOLCHAIN

COPY --from=builder ${TOOLS_PATH} ${TOOLS_PATH}
# Install basic programs and custom glibc
RUN apt-get update \
    && apt-get install -y \
        python3 \
        make \
        cmake \
        ccache \
        stlink-tools \ 
    && rm -rf /var/lib/apt/lists/* \
    && ls -la -R \
    && ln -s ${TOOLCHAIN}/bin/* /usr/local/bin \
    groupadd --gid $GID $GROUPNAME \
    useradd --uid $UID --gid $GID $USERNAME \
    usermod --append --groups $GROUPNAME $USERNAME \
    usermod --shell /bin/bash $USERNAME

ENV PATH=${TOOLCHAIN}/bin:$PATH \
    LD_LIBRARY_PATH=${TOOLCHAIN}/lib:$LD_LIBRARY_PATH \
    CC=${TARGET}-gcc \
    CXX=${TARGET}-g++ \
    CMAKE_C_COMPILER=${TARGET}-gcc \
    CMAKE_CXX_COMPILER=${TARGET}i-g++ \
    STRIP=${TARGET}-strip \
    RANLIB=${TARGET}-ranlib \
    AS=${TARGET}-as \
    AR=${TARGET}-ar \
    LD=${TARGET}-ld \
    FC=${TARGET}-gfortran

# Change workdir
WORKDIR /build

#CMD ["/bin/bash"]

USER $USERNAME