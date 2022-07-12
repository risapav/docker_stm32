.PHONY: all format-container shell image build-container 
.PHONY: clean-image clean-all
.PHONY: help
############################### Native Makefile ###############################
export MAKER_NAME ?= "docker_stm32"
export ROOT_DIR ?= ${PWD}

export PLATFORM ?= $(if $(OS),$(OS),$(shell uname -s))

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

export UID ?= $(shell id -u)
export GID ?= $(shell id -g)
export USER ?= $(shell id -un)
export GROUP ?= $(if $(filter $(PLATFORM), Windows_NT),$(shell id -un),$(shell id -gn))

ifeq ($(PLATFORM),Windows_NT)
    WIN_PREFIX = winpty
    WORKDIR_PATH = "//workdir"
    WORKDIR_VOLUME = "/$(ROOT_DIR):/$(WORKDIR_PATH)"
else
    WORKDIR_PATH = /workdir
    WORKDIR_VOLUME = "$(ROOT_DIR):/$(WORKDIR_PATH)"
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
	@echo "  build-container    - Build $(MAKER_NAME) container"
	@echo "  format-container   - Upload $(MAKER_NAME) to hub.docker.com"
	@echo "  clean-image        - Remove all $(MAKER_NAME) images"
	@echo "  clean-all          - Remove all $(MAKER_NAME) containers"
	@echo "  shell              - Bash prompt"
	@echo
	@echo "Constants:"
	@echo "  PLATFORM=$(PLATFORM)"
	@echo "  CONTAINER_TOOL=$(CONTAINER_TOOL)"
	@echo "  CONTAINER_FILE=$(CONTAINER_FILE)"
	@echo "  CONTAINER_NAME=$(CONTAINER_NAME)"
	@echo "  IMAGE_NAME=$(IMAGE_NAME)"
	@echo
	@echo "Variables:"
	@echo "  ROOT_DIR=$(ROOT_DIR)"
	@echo "  WORKDIR_VOLUME=$(WORKDIR_VOLUME)"
	@echo
	@echo "  UID=$(UID)"
	@echo "  GID=$(GID)"
	@echo "  USER=$(USER)"
	@echo "  GROUP=$(GROUP)"
	@echo
