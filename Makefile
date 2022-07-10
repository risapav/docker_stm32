.PHONY: all format-container shell image build-container 
.PHONY: clean-image clean-all
.PHONY: help
############################### Native Makefile ###############################
# pokus
PROJECT_NAME ?= firmware
BUILD_DIR ?= build
FIRMWARE := $(BUILD_DIR)/$(PROJECT_NAME).bin
BUILD_TYPE ?= Debug
PLATFORM = $(if $(OS),$(OS),$(shell uname -s))

ifeq ($(PLATFORM),Windows_NT)
    BUILD_SYSTEM ?= MinGW Makefiles
else
    ifeq ($(PLATFORM),Linux)
        BUILD_SYSTEM ?= Unix Makefiles
    else
        @echo "Unsuported platform"
        exit 1
    endif
endif

all: build-container

################################## Container ##################################

UID ?= $(shell id -u)
GID ?= $(shell id -g)
USER ?= $(shell id -un)
GROUP ?= $(if $(filter $(PLATFORM), Windows_NT),$(shell id -un),$(shell id -gn))

ifeq ($(PLATFORM),Windows_NT)
    WIN_PREFIX = winpty
    WORKDIR_PATH = "//workdir"
    WORKDIR_VOLUME = "/$$(pwd -W):/workdir"
else
    WORKDIR_PATH = /workdir
    WORKDIR_VOLUME = "$$(pwd):/workdir"
endif

CONTAINER_TOOL ?= docker
CONTAINER_FILE := Dockerfile
IMAGE_NAME := cross-arm-dev
CONTAINER_NAME := cross-arm-dev

NEED_IMAGE = $(shell $(CONTAINER_TOOL) image inspect $(IMAGE_NAME) 2> /dev/null > /dev/null || echo image)
# usefull if you have a always running container in the background: NEED_CONTAINER = $(shell $(CONTAINER_TOOL) container inspect $(CONTAINER_NAME) 2> /dev/null > /dev/null || echo container)
PODMAN_ARG = $(if $(filter $(CONTAINER_TOOL), podman),--userns=keep-id,)
CONTAINER_RUN = $(WIN_PREFIX) $(CONTAINER_TOOL) run \
				--name $(CONTAINER_NAME) \
				--rm \
				-it \
				$(PODMAN_ARG) \
				-v $(WORKDIR_VOLUME) \
				-w $(WORKDIR_PATH) \
				--security-opt label=disable \
				--hostname $(CONTAINER_NAME) \
				$(IMAGE_NAME)

build-container: $(NEED_IMAGE)
#	$(CONTAINER_RUN) bash -lc 'make -j$(shell nproc)'

format-container:
	$(CONTAINER_RUN) bash -lc 'make format -j$(shell nproc)'

shell:
	$(CONTAINER_RUN) bash -l

image: $(CONTAINER_FILE)
	$(CONTAINER_TOOL) build \
		-t $(IMAGE_NAME) \
		-f=$(CONTAINER_FILE) \
		--build-arg UID=$(UID) \
		--build-arg GID=$(GID) \
		--build-arg USERNAME=$(USER) \
		--build-arg GROUPNAME=$(GROUP) \
		.

clean-image:
	$(CONTAINER_TOOL) container rm -f $(CONTAINER_NAME) 2> /dev/null > /dev/null || true
	$(CONTAINER_TOOL) image rmi -f $(IMAGE_NAME) 2> /dev/null > /dev/null || true

clean-all: clean-image

help:
	@echo "Commands for working with docker images:"
	@echo "  build-container    - Build stm32 container"
	@echo "  format-container   - Upload stm32 to hub.docker.com"
	@echo "  clean-image        - Remove all docker stm32 images"
	@echo "  clean-all          - Remove all docker stm32 containers"
	@echo "  shell              - Bash prompt"
	@echo
	@echo "Variables:"
	@echo "  PROJECT_NAME=$(PROJECT_NAME firmware)"
	@echo "  BUILD_DIR=$(BUILD_DIR build)"
	@echo "  FIRMWARE=$(FIRMWARE)"
	@echo "  BUILD_TYPE=$(BUILD_TYPE)"
	@echo "  UID=$(UID)"
	@echo "  GID=$(GID)"
	@echo "  USER=$(USER)"
	@echo "  GROUP=$(GROUP)"
