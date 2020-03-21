FROM archlinux:latest

#update OS
RUN pacman -Sy \
	&& yes | pacman -S \
		stlink \
		openocd \
    && rm -rf /tmp/* /var/tmp/*

CMD ["/bin/bash"]
