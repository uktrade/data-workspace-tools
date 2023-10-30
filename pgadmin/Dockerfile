FROM python:3.11.6-bullseye

ENV \
	PGADMIN_LISTEN_ADDRESS=0.0.0.0 \
	PGADMIN_LISTEN_PORT=8888 \
	PGADMIN_DEFAULT_EMAIL=pgadmin4@pgadmin.org \
	PGADMIN_DEFAULT_PASSWORD=test

USER 0

RUN \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		locales \
        sudo && \
	echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen && \
	locale-gen en_GB.utf8

RUN pip install gunicorn pgadmin4

RUN mkdir /pgadmin4 && \
    groupadd -g 4356 pgadmin && \
    useradd -r -u 4357 -g pgadmin -m pgadmin && \
    mkdir -p /var/lib/pgadmin && \
    chown pgadmin:pgadmin /var/lib/pgadmin && \
    mkdir -p  /var/log/pgadmin && \
    touch /var/log/pgadmin/pgadmin4.log && \
    chown -R pgadmin:pgadmin /var/log/pgadmin && \
    chmod g=u /var/lib/pgadmin

COPY pgadmin/config_local.py /usr/local/lib/python3.11/site-packages/pgadmin4/
COPY pgadmin/start.sh /

RUN python3 /usr/local/lib/python3.11/site-packages/pgadmin4/setup.py

WORKDIR /pgadmin4
ENV PYTHONPATH=/pgadmin4

ENTRYPOINT ["/start.sh"]
