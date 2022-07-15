#STM32 development tools

# target system
# AArch32 bare-metal target (arm-none-eabi)
# TODO change to your ARM gcc toolchain path
ARG TOOLCHAIN_PREFIX:=arm-none-eabi
ARG TOOLCHAIN_ROOT:/opt
ARG TOOLCHAIN_PATH:=${TOOLCHAIN_ROOT}/${TOOLCHAIN_PREFIX}


# user and group settings
ARG UID
ARG GID
ARG USERNAME
ARG GROUPNAME

# stage 1
FROM debian:stable-slim as builder

# renew ARGS
ARG TOOLCHAIN_PREFIX
ARG TOOLCHAIN_ROOT
ARG TOOLCHAIN_PATH

# requested file     gcc-arm-11.2-2022.02-x86_64-arm-none-eabi.tar.xz
ARG TOOLS_ZIP=${TOOLCHAIN_PREFIX}.tar.xz
ARG TOOLS_LINK="https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/downloads"

# install build tools
RUN mkdir -p ${TOOLCHAIN_PATH} \  
    && apt-get update \
    && apt-get install -y \
        wget \
        w3m \
        tar \
        xz-utils \
        bzip2 \
    && rm -rf /var/lib/apt/lists/* 

WORKDIR ${TOOLCHAIN_PATH}

# grab required toolchain
RUN GCCARM_LINK="$(w3m -o display_link_number=1 -dump $TOOLS_LINK  | \
        sed -e 's/^\[[0-9]\+\] //' | \
        grep $TOOLS_ZIP | \
        grep 'x86_64'  | \
        grep 'downloads'  | \
        grep -m1 'https:' )" \
    && wget --content-disposition -q --show-progress --progress=bar:force:noscroll -O /tmp/${TOOLS_ZIP} ${GCCARM_LINK} 

RUN tar -xvf /tmp/${TOOLS_ZIP} -C ${TOOLCHAIN_PATH} --strip-components=1
    

# stage 2
FROM debian:stable-slim as gnu-cross-toolchain

# user and group settings
ARG UID
ARG GID
ARG USERNAME
ARG GROUPNAME

# renew ARGS
ARG TOOLCHAIN_PREFIX
ARG TOOLCHAIN_ROOT
ARG TOOLCHAIN_PATH

COPY --from=builder ${TOOLCHAIN_ROOT} ${TOOLCHAIN_ROOT}
# Install basic programs and custom glibc
RUN apt-get update \
    && apt-get install -y \
        python3 \
        make \
        cmake \
        ccache \
        stlink-tools \ 
    && rm -rf /var/lib/apt/lists/* \
    && ln -s ${TOOLCHAIN}/bin/* /usr/local/bin \
    && groupadd -g ${GID} ${GROUPNAME} \
    && useradd -u ${UID} -g ${GID} ${USERNAME} \
    && usermod --append --groups ${GROUPNAME} ${USERNAME} \
    && usermod --shell /bin/bash ${USERNAME}

ENV PATH=${TOOLCHAIN_PATH}/bin:$PATH \
    LD_LIBRARY_PATH=${TOOLCHAIN_PATH}/lib:$LD_LIBRARY_PATH \
    CC=${TOOLCHAIN_PREFIX}-gcc \
    CXX=${TOOLCHAIN_PREFIX}-g++ \
    CMAKE_C_COMPILER=${TOOLCHAIN_PREFIX}-gcc \
    CMAKE_CXX_COMPILER=${TOOLCHAIN_PREFIX}i-g++ \
    STRIP=${TOOLCHAIN_PREFIX}-strip \
    RANLIB=${TOOLCHAIN_PREFIX}-ranlib \
    AS=${TOOLCHAIN_PREFIX}-as \
    AR=${TOOLCHAIN_PREFIX}-ar \
    LD=${TOOLCHAIN_PREFIX}-ld \
    FC=${TOOLCHAIN_PREFIX}-gfortran

#CMD ["/bin/bash"]

USER ${USERNAME}
