# docker_stm32
stm32 Docker container building system

## Build Docker container

docker build -t stm32 .


## Run stm32 environment

Run Docker inside project directory. ST-link dongle should be plugged in USB.

docker run --rm --privileged -v /dev/bus/usb:/dev/bus/usb -v $PWD:/project -w /project -it stm32
