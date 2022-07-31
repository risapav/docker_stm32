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

# install crosscompile toolchain
RUN apt update && apt install -y \
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
  
# prepare missing python library
ARG PYTHON_PREFIX=python3
ARG PYTHON_PATH=/opt/${PYTHON_PREFIX}
ARG PYTHON_ZIP=Python-3.6.14.tgz
ARG PYTHON_LINK=https://www.python.org/ftp/python/3.6.14/Python-3.6.14.tgz

RUN mkdir -p ${PYTHON_PATH}; \
  mkdir -p /tmp/${PYTHON_PREFIX}; \
  cd /tmp/${PYTHON_PREFIX}; \
  wget -O ${PYTHON_ZIP} ${PYTHON_LINK}; \
  tar xf ${PYTHON_ZIP}; \
cd Python-3.6.14; \
cat configure; \
./configure --prefix=${PYTHON_PATH} --enable-shared; \
make -j"$(nproc)"; \
make install -j"$(nproc)"; \

# We can see that we've produced shared library (.so file successfully):

find / -name libpython3.6m.so.1.0
# ./libpython3.6m.so.1.0
# ./lib/libpython3.6m.so.1.0

# Trick is to tell GDB where to look for shared libs with LD_LIBRARY_PATH environment variable.


# $ LD_LIBRARY_PATH=/tmp/tt/python3.6/lib ./bin/arm-none-eabi-gdb --version
# GNU gdb (GNU Toolchain for the Arm Architecture 11.2-2022.02 (arm-11.14)) 11.2.90.20220202-git


# stage 2  
FROM risapav/docker_sshd:latest

ARG SSH_PUB_KEY
ARG USERNAME

# renew ARGS
ARG TOOLCHAIN_PREFIX
ARG TOOLCHAIN_ROOT
ARG TOOLCHAIN_PATH

# copy entire dir with bin, lib docs...
COPY --from=builder ${TOOLCHAIN_ROOT} ${TOOLCHAIN_ROOT}

# install apps
RUN apt update && apt install -y \
    make \
    cmake \
    gdb-multiarch \
#    ccache \ 
#    python3 \
#    libpython-all-dev \
    stlink-tools; \ 
  apt clean; \
  ln -s ${TOOLCHAIN_PATH}/bin/* /usr/local/bin; \
  ln -s /lib/x86_64-linux-gnu/libncursesw.so.6.2 /lib/x86_64-linux-gnu/libncursesw.so.5; \
  ln -s /lib/x86_64-linux-gnu/libtinfo.so.6.2 /lib/x86_64-linux-gnu/libtinfo.so.5; \ 
  { \
    echo "export LD_LIBRARY_PATH=${TOOLCHAIN_PATH}/lib:$LD_LIBRARY_PATH"; \
    echo "export CC=${TOOLCHAIN_PREFIX}-gcc"; \
    echo "export CXX=${TOOLCHAIN_PREFIX}-g++"; \
    echo "export CMAKE_C_COMPILER=${TOOLCHAIN_PREFIX}-gcc"; \
    echo "export CMAKE_CXX_COMPILER=${TOOLCHAIN_PREFIX}-g++"; \
    echo "export STRIP=${TOOLCHAIN_PREFIX}-strip"; \
    echo "export RANLIB=${TOOLCHAIN_PREFIX}-ranlib"; \
    echo "export AS=${TOOLCHAIN_PREFIX}-as"; \
    echo "export AR=${TOOLCHAIN_PREFIX}-ar"; \
    echo "export LD=${TOOLCHAIN_PREFIX}-ld"; \
    echo "export GDB=${TOOLCHAIN_PREFIX}-gdb"; \
    echo "export SIZE=${TOOLCHAIN_PREFIX}-size"; \
    echo "# export BIN=${TOOLCHAIN_PREFIX}-objcopy -O ihex"; \
    echo "export OD=${TOOLCHAIN_PREFIX}-objdump"; \
    echo "export FC=${TOOLCHAIN_PREFIX}-gfortran"; \
  } >> /etc/profile; \
  ls -la ${TOOLCHAIN_PATH}/bin; 

#ENV SHELL=/bin/bash \
#    LD_LIBRARY_PATH=${TOOLCHAIN_PATH}/lib:$LD_LIBRARY_PATH \
#    CC=${TOOLCHAIN_PREFIX}-gcc \
#    CXX=${TOOLCHAIN_PREFIX}-g++ \
#    CMAKE_C_COMPILER=${TOOLCHAIN_PREFIX}-gcc \
#    CMAKE_CXX_COMPILER=${TOOLCHAIN_PREFIX}-g++ \
#    STRIP=${TOOLCHAIN_PREFIX}-strip \
#    RANLIB=${TOOLCHAIN_PREFIX}-ranlib \
#    AS=${TOOLCHAIN_PREFIX}-as \
#    AR=${TOOLCHAIN_PREFIX}-ar \
#    LD=${TOOLCHAIN_PREFIX}-ld \
#    FC=${TOOLCHAIN_PREFIX}-gfortran \
#    OD=$(TOOLCHAIN_PREFIX)-objdump \
##    BIN=$(TOOLCHAIN_PREFIX)-objcopy -O ihex \
#    SIZE=$(TOOLCHAIN_PREFIX)-size \
#    GDB=$(TOOLCHAIN_PREFIX)-gdb 

# EXPOSE 3333 

# CMD ["/bin/bash"]
