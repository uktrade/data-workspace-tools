FROM debian:bullseye-20220328

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
	curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install -y nodejs && \
    rm /etc/apt/sources.list.d/nodesource.list && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt python-setup.sh /root/

RUN \
	addgroup --system --gid 4356 vscode && \
	adduser --disabled-password --gecos '' --ingroup vscode --uid 4357 vscode

RUN \
	mkdir -p "$CONDA_DIR" && \
	curl https://repo.anaconda.com/miniconda/Miniconda3-py39_4.11.0-Linux-aarch64.sh --output /root/miniconda.sh && \
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
    chown -R vscode:vscode /opt/conda

WORKDIR /root
RUN \
    curl -fsSL https://code-server.dev/install.sh | sh

RUN \
	mkdir /certs

COPY rds-global-bundle.pem /certs/rds-global-bundle.pem
COPY dw-install /usr/bin/dw-install
COPY glfsm /usr/bin/glfsm
COPY vscode/start.sh /start.sh

# The ipython history database does not play well with mobius3, surfacing
# occasional errors like "attempt to write a readonly database", so we store
# it where mobius3 does not sync
ENV IPYTHONDIR=/tmp/ipython

ENV \
    JUPYTER_CONFIG_DIR=/home/jovyan/.jupyter_theia \
    JUPYTER_DATA_DIR=/tmp/jupyter_theia \
    JUPYTER_RUNTIME_DIR=/tmp/jupyter_theia/runtime

CMD ["/start.sh"]
