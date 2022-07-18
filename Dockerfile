#STM32 development tools

# supply your pub key via `--build-arg ssh_pub_key="$(cat ~/.ssh/id_rsa.pub)"` when running `docker build`
ARG SSH_PUB_KEY

# target system
# AArch32 bare-metal target (arm-none-eabi)
# TODO change to your ARM gcc toolchain path
ARG TOOLCHAIN_PREFIX=arm-none-eabi
ARG TOOLCHAIN_ROOT=/opt
ARG TOOLCHAIN_PATH=${TOOLCHAIN_ROOT}/${TOOLCHAIN_PREFIX}


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
RUN echo "--> TOOLCHAIN_PATH=${TOOLCHAIN_PATH} " \
    && mkdir -p ${TOOLCHAIN_PATH} \  
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

# ssh keys
WORKDIR /tmp   

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

# install apps
RUN apt-get update \
    && apt-get install -y \
        # open ssh server 
        openrc \
        openssh-server \
        mc \
        # toolchain
        python3 \
        make \
        cmake \
        ccache \
        stlink-tools \ 
    && rm -rf /var/lib/apt/lists/* \
    && ln -s ${TOOLCHAIN}/bin/* /usr/local/bin \
    && groupadd -g ${GID} ${GROUPNAME} \
    && useradd -m -u ${UID} -g ${GID} ${USERNAME} \
    && usermod --append --groups ${GROUPNAME} ${USERNAME} \
    && usermod --shell /bin/bash ${USERNAME} \
    # create user SSH configuration
# root access to ssh server
    && mkdir -p root/.ssh \
    # only this user should be able to read this folder (it may contain private keys)
    && chmod 0700 root/.ssh \
    # unlock the user
    && passwd -u root \
    && echo "$SSH_PUB_KEY" > /root/.ssh/authorized_keys \
# sshd server
#    && mkdir /var/run/sshd  \
#    && echo 'root:root' | chpasswd \
#    && sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config \
#    && sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config \
#    && mkdir /root/.ssh \
    && cd /etc/ssh/ && ssh-keygen -A \
    && echo "PasswordAuthentication no" >> /etc/ssh/sshd_config \
    && mkdir -p /run/openrc \
    && touch /run/openrc/softlevel \
    && mkdir -p /home/${USERNAME}/.ssh  \
    && echo "$SSH_PUB_KEY" > /home/${USERNAME}/.ssh/authorized_keys \
    && echo "export VISIBLE=now" >> /etc/profile 

#ENV NOTVISIBLE "in users profile" \
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



USER ${USERNAME}

EXPOSE 22

ENTRYPOINT service ssh start && bash
#ENTRYPOINT ["/usr/sbin/sshd", "-c", "rc-status; rc-service sshd start"]
CMD    ["/usr/sbin/sshd", "-D"]
#CMD ["/bin/bash"]