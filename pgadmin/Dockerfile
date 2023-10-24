FROM dpage/pgadmin4:7.6

ENV \
	PGADMIN_LISTEN_ADDRESS=0.0.0.0 \
	PGADMIN_LISTEN_PORT=8888 \
	PGADMIN_DEFAULT_EMAIL=pgadmin4@pgadmin.org \
	PGADMIN_DEFAULT_PASSWORD=test

COPY pgadmin/pgadmin-config.py /pgadmin4/config_local.py
COPY pgadmin/start.sh /

USER root

ENTRYPOINT ["/start.sh"]
