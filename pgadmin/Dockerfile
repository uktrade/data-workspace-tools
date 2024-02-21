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

# Set preferences to not show the dashboard on startup, which (at best) makes the logs of
# what's doing on in the database really noisy, and at worst has performance implications
# Note that we have to actually run pgadmin4 first, and only then is it possible to set preferences
# This is because `set-prefs` depends on rows in the SQLite preference database that, as far we
# we can tell, only get created after pgadmin4 has run properly. We don't have a way of detecting
# if pgadmin4 has run enough to actually create the preference rows, but it really should have in
# 20 seconds, and we only build this Docker image occasionally
RUN \
	(timeout 20s pgadmin4; exit 0) && \
	python3 /usr/local/lib/python3.11/site-packages/pgadmin4/setup.py set-prefs pgadmin4@pgadmin.org 'dashboards:display:show_graphs=false' 'dashboards:display:show_activity=false'

WORKDIR /pgadmin4
ENV PYTHONPATH=/pgadmin4

ENTRYPOINT ["/start.sh"]
