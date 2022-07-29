#STM32 development tools


# supply your pub key via `--build-arg ssh_pub_key="$(cat ~/.ssh/id_rsa.pub)"` when running `docker build`
# docker build example:
# docker build --build-arg SSH_PUB_KEY="$(cat ~/.ssh/id_rsa.pub)" --build-arg USERNAME=$USER -t sshd .
ARG SSH_PUB_KEY

# user and group settings `--build-arg USERNAME=$USER`
ARG USERNAME

# target system
# AArch32 bare-metal target (arm-none-eabi)

# prefixes arm-none-linux-gnueabihf arm-none-eabi aarch64-none-elf aarch64-none-linux-gnu aarch64_be-none-linux-gnu
ARG TOOLCHAIN_PREFIX=arm-none-eabi
ARG TOOLCHAIN_ROOT=/opt
ARG TOOLCHAIN_PATH=${TOOLCHAIN_ROOT}/${TOOLCHAIN_PREFIX}

# targer architecture x84_64 mingw-w64-i686 aarch64 darwin-x86_64
ARG TOOLCHAIN_HOST=x86_64

# stage 1
FROM debian:stable-slim as builder

# renew ARGS
ARG TOOLCHAIN_PREFIX
ARG TOOLCHAIN_ROOT
ARG TOOLCHAIN_PATH
ARG TOOLCHAIN_HOST

# requested file     
# gcc-arm-11.2-2022.02-x86_64-arm-none-eabi.tar.xz
# gcc-arm-11.2-2022.02-x86_64-arm-none-linux-gnueabihf.tar.xz
ARG TOOLS_ZIP=${TOOLCHAIN_PREFIX}.tar.xz
ARG TOOLS_LINK="https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/downloads"

# install build tools
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN echo "Build parameters --> TOOLCHAIN_PATH=${TOOLCHAIN_PATH}"; \  
  apt update && apt install -y \
    wget \
    w3m \
    tar \
    xz-utils \
    bzip2; \
  apt clean; \ 
  mkdir -p ${TOOLCHAIN_PATH}; \
  cd ${TOOLCHAIN_PATH}; \
  echo "==========>>> ${TOOLCHAIN_PATH} ${TOOLS_ZIP} ${TOOLCHAIN_HOST}"; \
# grab required toolchain
  GCCARM_LINK="$(w3m -o display_link_number=1 -dump $TOOLS_LINK  | \
    sed -e 's/^\[[0-9]\+\] //' | \
    grep ${TOOLS_ZIP} | \
    grep ${TOOLCHAIN_HOST}  | \
    grep 'downloads'  | \
    grep -m1 'https:' )"; \
  echo "==========>>> ${GCCARM_LINK}"; \
  wget --content-disposition -q --show-progress --progress=bar:force:noscroll -O /tmp/${TOOLS_ZIP} ${GCCARM_LINK}; \
  tar -xvf /tmp/${TOOLS_ZIP} -C ${TOOLCHAIN_PATH} --strip-components=1;

# stage 2
# FROM git@github.com:risapav/docker_sshd.git
FROM risapav/docker_sshd:latest
# FROM debian:stable-slim as gnu-cross-toolchain

ARG SSH_PUB_KEY
ARG USERNAME

# renew ARGS
ARG TOOLCHAIN_PREFIX
ARG TOOLCHAIN_ROOT
ARG TOOLCHAIN_PATH

COPY --from=builder ${TOOLCHAIN_ROOT} ${TOOLCHAIN_ROOT}
# Install basic programs and custom glibc

ENV SHELL=/bin/bash \
    LD_LIBRARY_PATH=${TOOLCHAIN_PATH}/lib:$LD_LIBRARY_PATH \
    CC=${TOOLCHAIN_PREFIX}-gcc \
    CXX=${TOOLCHAIN_PREFIX}-g++ \
    CMAKE_C_COMPILER=${TOOLCHAIN_PREFIX}-gcc \
    CMAKE_CXX_COMPILER=${TOOLCHAIN_PREFIX}-g++ \
    STRIP=${TOOLCHAIN_PREFIX}-strip \
    RANLIB=${TOOLCHAIN_PREFIX}-ranlib \
    AS=${TOOLCHAIN_PREFIX}-as \
    AR=${TOOLCHAIN_PREFIX}-ar \
    LD=${TOOLCHAIN_PREFIX}-ld \
    FC=${TOOLCHAIN_PREFIX}-gfortran 
    
ENV NOTVISIBLE "in users profile"

# install apps
RUN echo "export VISIBLE=now" >> /etc/profile; \
  apt update && apt install -y \
    # toolchain
    python3 \
    make \
    cmake \
    ccache \
    stlink-tools; \ 
  apt clean; \
  ln -s ${TOOLCHAIN_PATH}/bin/* /usr/local/bin; \
  ls -la ${TOOLCHAIN_PATH}/bin; 

# CMD ["/bin/bash"]
