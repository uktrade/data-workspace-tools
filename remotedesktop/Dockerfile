FROM debian:bullseye

RUN \
	apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		bzip2 \
		ca-certificates \
		nginx \
		procps \
		dbus-x11 \
		openbox \
		sudo \
		lxqt-themes \
		task-lxqt-desktop \
		tigervnc-standalone-server \
		vim \
		gnupg \
		software-properties-common \
		gzip \
		gretl \
		python3-setuptools \
		wget

RUN \
	wget -O - https://download.qgis.org/downloads/qgis-2022.gpg.key | gpg --import && \
	gpg --export --armor D155B8E6A419C5BE | sudo gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/qgis-archive.gpg --import && \
	sudo chmod a+r /etc/apt/trusted.gpg.d/qgis-archive.gpg && \
	add-apt-repository "deb https://qgis.org/debian $(lsb_release -c -s) main" && \
	apt update && \
	apt install qgis qgis-plugin-grass -y && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN \
	wget https://github.com/novnc/websockify/archive/refs/tags/v0.9.0.tar.gz && \
	tar -zxvf v0.9.0.tar.gz && \
	cd websockify-0.9.0 && \
	python3 setup.py install && \
	cd .. && \
	rm -r -f v0.9.0.tar.gz

COPY index.html /webroot/index.html

RUN gzip -c /webroot/index.html > /webroot/index.html.gz

RUN \
	addgroup --system --gid 4356 dw && \
	adduser --disabled-password --gecos '' --ingroup dw --uid 4357 dw && \
	echo "root ALL=(ALL:ALL) ALL" > /etc/sudoers && \
	touch /var/run/nginx.pid && \
	chown dw:dw /var/run/nginx.pid

COPY start.sh nginx.conf org.qgis.qgis.desktop gretl.desktop /
COPY lxqt /etc/xdg/lxqt

ENV \
	USER=dw

CMD ["/start.sh"]
