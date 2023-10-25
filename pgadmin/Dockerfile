FROM dpage/pgadmin4:7.8

ENV \
	PGADMIN_LISTEN_ADDRESS=0.0.0.0 \
	PGADMIN_LISTEN_PORT=8888 \
	PGADMIN_DEFAULT_EMAIL=pgadmin4@pgadmin.org \
	PGADMIN_DEFAULT_PASSWORD=test \
	PGADMIN_CONFIG_WTF_CSRF_CHECK_DEFAULT=False \
    PGADMIN_CONFIG_WTF_CSRF_ENABLED=False

COPY pgadmin/pgadmin-config.py /pgadmin4/config_local.py
COPY pgadmin/start.sh /

USER root

ENTRYPOINT ["/start.sh"]
