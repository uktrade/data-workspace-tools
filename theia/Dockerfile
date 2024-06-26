FROM debian:bullseye-20240211

RUN \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		locales && \
	echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen && \
	locale-gen en_GB.utf8 && \
	rm -rf /var/lib/apt/lists/*

ENV \
	LC_ALL=en_GB.UTF-8 \
	LANG=en_GB.UTF-8 \
	LANGUAGE=en_GB.UTF-8 \
	CONDA_DIR=/opt/conda

ENV \
	PATH="$CONDA_DIR/bin:$PATH"

RUN \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		ca-certificates \
		dirmngr \
		gnupg2 && \
	rm -rf /var/lib/apt/lists/* && \
	echo "deb https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/debian/ bullseye main" > /etc/apt/sources.list && \
	echo "deb https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/debian/ bullseye-updates main" >> /etc/apt/sources.list && \
	echo "Acquire{Check-Valid-Until false; Retries 10;}" >> /etc/apt/apt.conf

RUN \
	apt-get update && \
	apt-get install -y \
		build-essential \
		git \
		git-lfs \
		curl \
		libfreetype-dev \
		man-db \
		vim \
		emacs \
		procps \
		sudo \
		pkg-config \
		libsecret-1-dev && \
	curl -sL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm /etc/apt/sources.list.d/nodesource.list && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt python-setup.sh /root/

RUN \
	addgroup --system --gid 4356 theia && \
	adduser --disabled-password --gecos '' --ingroup theia --uid 4357 theia

RUN \
	mkdir -p "$CONDA_DIR" && \
	curl https://repo.anaconda.com/miniconda/Miniconda3-py39_24.3.0-0-Linux-x86_64.sh --output /root/miniconda.sh && \
	echo "1c3d44e987dc56c7d8954419fa1a078be5ddbc293d8cb98b184a23f9a270faad /root/miniconda.sh" | sha256sum --check --status && \
	bash /root/miniconda.sh -f -b -p "$CONDA_DIR" && \
	echo 'channels:' > /opt/conda/.condarc && \
	echo '  - https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/conda-forge/' >> /opt/conda/.condarc && \
	echo '  - https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/anaconda/' >> /opt/conda/.condarc && \
	echo 'allow_other_channels: false' >> /opt/conda/.condarc && \
	echo 'auto_update_conda: false' >> /opt/conda/.condarc && \
	echo 'always_yes: true' >> /opt/conda/.condarc && \
	echo 'show_channel_urls: true' >> /opt/conda/.condarc

RUN \
    echo '[global]' > /etc/pip.conf && \
    echo 'index-url = https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/pypi/' >> /etc/pip.conf && \
    echo 'no-cache-dir = false' >> /etc/pip.conf

RUN \
    /root/python-setup.sh && \
    chown -R theia:theia /opt/conda

WORKDIR /root
RUN \
    curl -o- -L https://yarnpkg.com/install.sh | bash

ENV \
	PATH="/root/.yarn/bin:/root/node_modules/.bin:$PATH"

COPY theia/package.json /root
COPY theia/yarn.lock /root

RUN \
	yarn install && \
	yarn theia download:plugins && \
	yarn theia build && \
	yarn cache clean && \
	find /root -type d -exec chmod 755 {} + && \
	chmod -R +r /root

RUN \
	mkdir /tmp/.yarn-cache && \
	chown theia:theia /tmp/.yarn-cache && \
	touch /root/yarn-error.log && \
	chown theia:theia /root/yarn-error.log && \
	echo "root ALL=(ALL:ALL) ALL" > /etc/sudoers && \
	echo "theia ALL=NOPASSWD:/usr/bin/dw-install" >> /etc/sudoers && \
	echo 'PS1="\w\\\\$ \[$(tput sgr0)\]"' >> /etc/bash.bashrc && \
	echo "conda activate base" >> /etc/profile && \
	ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
	rm /home/theia/.bashrc && \
	rm /home/theia/.profile

RUN \
	mkdir /certs

COPY rds-global-bundle.pem /certs/rds-global-bundle.pem
COPY dw-install /usr/bin/dw-install
COPY glfsm /usr/bin/glfsm
COPY theia/vscode_postgres.theia /root/plugins/vscode_postgres.theia
COPY theia/start.sh /start.sh

# The ipython history database does not play well with mobius3, surfacing
# occasional errors like "attempt to write a readonly database", so we store
# it where mobius3 does not sync
ENV IPYTHONDIR=/tmp/ipython

ENV \
    JUPYTER_CONFIG_DIR=/home/jovyan/.jupyter_theia \
    JUPYTER_DATA_DIR=/tmp/jupyter_theia \
    JUPYTER_RUNTIME_DIR=/tmp/jupyter_theia/runtime

ENV \
	# Theia by default puts webviews on a subdomain, requests to which I think are intercepted by
	# a service worker. This doesn't work with the locked down DW CSP
	THEIA_WEBVIEW_EXTERNAL_ENDPOINT={{hostname}} \
	SHELL=/bin/bash

CMD ["/start.sh"]
