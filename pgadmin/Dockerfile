FROM python:3.11.6-bullseye AS app-builder

# https://github.com/pgadmin-org/pgadmin4/blob/master/Dockerfile

ENV \
	PGADMIN_LISTEN_ADDRESS=0.0.0.0 \
	PGADMIN_LISTEN_PORT=8888 \
	PGADMIN_DEFAULT_EMAIL=pgadmin4@pgadmin.org \
	PGADMIN_DEFAULT_PASSWORD=test \
	SETUPTOOLS_USE_DISTUTILS=stdlib \
	DEBIAN_FRONTEND=noninteractive

COPY pgadmin/requirements.txt /

USER 0

RUN \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		locales \
        curl \
        gnupg \
        ca-certificates \
        lsb-release \
        libcap2-bin \
        sudo \
        python3 \
        python3-pip \
        python3-dev \
        python3-setuptools \
        gcc \
        krb5-config \
        libkrb5-dev && \
	echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen && \
	locale-gen en_GB.utf8
#	rm -rf /var/lib/apt/lists/*

RUN \
    python3 -m venv --system-site-packages --without-pip /venv && \
    /venv/bin/python3 -m pip install --no-deps -r requirements.txt

RUN curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg
RUN sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" >> /etc/apt/sources.list.d/pgadmin4.list && apt update'
RUN apt-get update && \
    apt-cache search pgadmin4 && \
    apt update && \
    apt policy pgadmin4-desktop && \
    apt-get install -y \
      pgadmin4-desktop  \
      gunicorn

RUN mkdir /pgadmin
COPY pgadmin/run_pgadmin.py /pgadmin4
COPY pgadmin/gunicorn_config.py /pgadmin4
COPY pgadmin/entrypoint.sh /entrypoint.sh
COPY pgadmin/pgadmin-config.py /pgadmin4/config_local.py
COPY pgadmin/start.sh /

RUN \
    useradd -r -u 5050 -g root pgadmin && \
    mkdir -p /var/lib/pgadmin && \
    chown pgadmin:root /var/lib/pgadmin && \
    chmod g=u /var/lib/pgadmin && \
    touch /pgadmin4/config_distro.py && \
    chown pgadmin:root /pgadmin4/config_distro.py && \
    chmod g=u /pgadmin4/config_distro.py && \
    chmod g=u /etc/passwd
#    setcap CAP_NET_BIND_SERVICE=+eip /usr/bin/python3.11 && \


#
#USER root
#RUN \
#	usermod -u 4357 pgadmin && \
#    groupadd pgadmin && \
#    groupmod -g 4356 pgadmin && \
#	chmod +x /start.sh

ENTRYPOINT ["/start.sh"]
