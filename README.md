# docker_stm32
A simple Docker container building system for developing SW for STM32


## Clone

Make sure git is installed.
```sh
git clone https://github.com/risapav/docker_stm32 && docker_stm32
```

## Build Docker container

```sh
docker build -t stm32 .
```

## Run stm32 environment

Run Docker inside project directory. ST-link dongle should be plugged in USB.

```sh
docker run --rm --privileged -v /dev/bus/usb:/dev/bus/usb -v $PWD:/project -w /project -it stm32
```
## Inside container try run this:

```sh
[root@599a1acb72f3 project]# arm-none-eabi-cpp --version
[root@599a1acb72f3 project]# st-flash --version
[root@599a1acb72f3 project]# make -version
[root@599a1acb72f3 project]# cmake -version
[root@599a1acb72f3 project]# make && make flash
```
