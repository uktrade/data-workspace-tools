# Multi-stage Dockerfile for Data Workspace Tools and Visualisations. While this makes the file
# long, having this as a single Dockerfile makes it much easier to ensure consistency between the
# tools and visualisations. For example, this makes it easier to same command line tools installed
# everywhere, and makes it more likely that a visualisation working locally in a tool will likely
# work when deployed.
#
# The hierarchy of stages is:
#
# base
# ├── python
# │   ├── python-jupyterLab
# │   ├── python-theia
# │   └── python-visualisation
# ├── rv4
# │   ├── rv4-cran-binary-mirror
# │   └── rv4-common-packages
# │       ├── rv4-rstudio
# │       └── rv4-visualisation
# ├── pgadmin
# ├── remote-desktop
# ├── s3sync
# └── metrics


###################################################################################################
# The base image for all tools and visualisations, containing common configuration and packages

FROM --platform=linux/amd64 debian:bullseye AS base

ENV \
    DEBIAN_FRONTEND=noninteractive \
    SHELL=/bin/bash \
    USER=dw-user \
    PGSSLROOTCERT=/certs/rds-global-bundle.pem \
    PGSSLMODE=verify-full

RUN \
    # Install ca-certificates from our mirror, but we can't verify the HTTPS cert because we don't
    # yet have ca-certificates installed (Debian signs the packages so, so this should be safe)
    echo "deb https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/debian/ bullseye main" > /etc/apt/sources.list && \
    echo "deb https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/debian-security/ bullseye-security main" >> /etc/apt/sources.list && \
    echo "deb https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/debian/ bullseye-updates main" >> /etc/apt/sources.list && \
    echo "Acquire { Check-Valid-Until false; Retries 10; }" >> /etc/apt/apt.conf && \
    echo "Acquire { https::Verify-Peer false }" > /etc/apt/apt.conf.d/99verify-peer.conf && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    \
    # Make sure to verify HTTPS when installing packages from our mirror from now onwards
    # (Technically unnecessary since as mentioned above, Debian signs packages)
    rm /etc/apt/apt.conf.d/99verify-peer.conf && \
    \
    # Install and configure locales, sudo, and the user and group to run tools under
    apt-get update && \
    apt-get install -y --no-install-recommends \
        locales \
        sudo && \
    rm -rf /var/lib/apt/lists/* && \
    echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen en_GB.UTF-8 && \
    groupadd -g 4356 dw-user && \
    useradd -u 4357 dw-user -g dw-user -m && \
    echo "root ALL=(ALL:ALL) ALL" > /etc/sudoers && \
    echo "dw-user ALL=NOPASSWD:/usr/bin/dw-install" >> /etc/sudoers && \
    \
    # The home directory in Data Workspace is a volume that is empty by default,
    # so there is no ~/.bashrc. We delete the one here to make testing locally
    # more like production
    rm /home/dw-user/.bashrc && \
    rm /home/dw-user/.profile && \
    \
    # Have a slightly nicer shell prompt by default
    echo 'PS1="\w\\\\$ \[$(tput sgr0)\]"' >> /etc/bash.bashrc && \
    \
    # Avoids errors when installing Java
    mkdir -p /usr/share/man/man1mkdir -p /usr/share/man/man1

# Local variables must be set after local-gen, otherwise local-gen fails
ENV \
    LC_ALL=en_GB.UTF-8 \
    LANG=en_GB.UTF-8 \
    LANGUAGE=en_GB.UTF-8

COPY base/rds-global-bundle.pem /certs/
COPY base/dw-install base/glfsm /usr/bin/

WORKDIR /home/dw-user


###################################################################################################
# Base for all Python-based tools and visualisations

FROM base AS python

ENV \
    CONDA_DIR=/opt/conda \
    PATH="/opt/conda/bin:$PATH" \
    \
    # The ipython history database does not play well with mobius3, surfacing
    # occasional errors like "attempt to write a readonly database", so we store
    # it where mobius3 does not sync
    IPYTHONDIR=/tmp/ipython \
    JUPYTER_CONFIG_DIR=/home/dw-user/.jupyterlab_python \
    JUPYTER_DATA_DIR=/tmp/jupyterlab_python \
    JUPYTER_RUNTIME_DIR=/tmp/jupyterlab_python/runtime

RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        dirmngr \
        emacs \
        fonts-dejavu-core \
        git \
        git-lfs \
        git-man \
        gnupg2 \
        libfreetype-dev \
		libsecret-1-dev \
        libxext6 \
        libxrender1 \
        man-db \
        openssh-client \
        openssl \
		pkg-config \
        ssh \
        sudo \
        texlive-fonts-recommended \
        texlive-plain-generic \
        texlive-xetex \
        tini \
        vim \
        wget && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3 1 && \
    wget -q -O - https://deb.nodesource.com/setup_20.x | bash  && \
    apt-get install -y nodejs && \
    apt-get remove --purge -y \
        wget && \
    rm /etc/apt/sources.list.d/nodesource.list && \
    rm -rf /var/lib/apt/lists/* && \
    \
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
    echo 'show_channel_urls: true' >> /opt/conda/.condarc && \
    \
    echo '[global]' > /etc/pip.conf && \
    echo 'index-url = https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/pypi/' >> /etc/pip.conf && \
    echo 'no-cache-dir = false' >> /etc/pip.conf

COPY \
    python/requirements.txt /root/

RUN \
    python3 -m pip install --upgrade pip setuptools wheel && \
    python3 -m pip install -r /root/requirements.txt && \
    chown -R dw-user:dw-user /usr/local && \
    chown -R dw-user:dw-user /opt/conda


###################################################################################################
# JupyterLab

FROM python AS python-jupyterlab

COPY python-jupyterlab/jupyter_notebook_config.py /etc/jupyter/jupyter_notebook_config.py
COPY python-jupyterlab/start.sh /

CMD ["/start.sh"]
ENTRYPOINT ["tini", "-g", "--"]


###################################################################################################
# Theia

FROM python AS python-theia

ENV \
	PATH="/root/.yarn/bin:/root/node_modules/.bin:$PATH" \
	# Theia by default puts webviews on a subdomain, requests to which I think are intercepted by
	# a service worker. This doesn't work with the locked down DW CSP
	THEIA_WEBVIEW_EXTERNAL_ENDPOINT={{hostname}}

COPY python-theia/package.json /root
COPY python-theia/yarn.lock /root

RUN \
    cd /root && \
    curl -o- -L https://yarnpkg.com/install.sh | bash && \
	yarn install && \
	yarn theia download:plugins && \
	yarn theia build && \
	yarn cache clean && \
	find /root -type d -exec chmod 755 {} + && \
	chmod -R +r /root && \
    \
	mkdir /tmp/.yarn-cache && \
	chown dw-user:dw-user /tmp/.yarn-cache && \
	touch /root/yarn-error.log && \
	chown dw-user:dw-user /root/yarn-error.log && \
	echo "conda activate base" >> /etc/profile && \
	ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh

COPY python-theia/vscode_postgres.theia /root/plugins/vscode_postgres.theia
COPY python-theia/start.sh /start.sh

CMD ["/start.sh"]


###################################################################################################
# Base for Python visualisations

FROM python AS python-visualisation

# Uses the python base, nothing extra required


###################################################################################################
# Base for all R version 4 tools and visualisations

FROM base AS rv4

RUN \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		dirmngr \
		gnupg2 && \
	echo "deb http://cran.ma.imperial.ac.uk/bin/linux/debian bullseye-cran40/" >> /etc/apt/sources.list && \
	until apt-key adv --keyserver keyserver.ubuntu.com --recv-key '95C0FAF38DB3CCAD0C080A7BDC78B2DDEABC47B7'; do sleep 10; done && \
    apt-get remove --purge -y \
        dirmngr \
        gnupg2 && \
    rm -rf /var/lib/apt/lists/* && \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		emacs \
		gdebi-core \
		gfortran \
		git \
		git-man \
		libcairo2-dev \
		libfontconfig1-dev \
		libfribidi-dev \
		libgdal-dev \
		libgit2-dev \
		libgsl-dev \
		libharfbuzz-dev \
		libjq-dev \
		libmagick++-dev \
		libnode-dev \
		libpq-dev \
		libprotobuf-dev \
		libprotobuf-dev \
		libssl-dev \
		libudunits2-dev \
		libv8-dev \
		libxml2-dev \
		lmodern \
		man-db \
		procps \
		protobuf-compiler \
		r-base-dev \
		r-base \
		r-recommended \
		ssh \
		texlive \
		texlive-latex-extra \
		vim \
		wget && \
	rm -rf /var/lib/apt/lists/* && \
    # Remove the last line from sources: the CRAN debian repo that has R itself, which we don't mirror
    sed -i '$d' /etc/apt/sources.list && \
    \
    # Configure R
    R_VERSION=$(Rscript -e 'cat(paste0(getRversion()$major, ".", getRversion()$minor))') && \
    echo 'local({' >> /usr/lib/R/etc/Rprofile.site && \
    echo '  r = getOption("repos")' >> /usr/lib/R/etc/Rprofile.site && \
    echo '  r["CRAN"] = "https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/cran-binary-debian-bullseye-r-'$R_VERSION'/"' >> /usr/lib/R/etc/Rprofile.site && \
    echo '  r["CRAN_1"] = "https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/cran/"' >> /usr/lib/R/etc/Rprofile.site && \
    echo '  options(repos = r)' >> /usr/lib/R/etc/Rprofile.site && \
    echo '})' >> /usr/lib/R/etc/Rprofile.site && \
    echo '' >> /usr/lib/R/etc/Rprofile.site && \
    \
    # Allow the run-time user to install R packages
	chown -R dw-user:dw-user /usr/local/lib/R/site-library && \
    \
	echo 'export PATH="/home/dw-user/.local/bin:$PATH"' >> /etc/bash.bashrc


###################################################################################################
# CRAN binary mirror

FROM rv4 AS rv4-cran-binary-mirror

COPY rv4-cran-binary-mirror/build.R /home

CMD Rscript /home/build.R


###################################################################################################
# R version 4 with a set of common packages

FROM rv4 AS rv4-common-packages

RUN \
    # Build in new directory to make cleanup easier
    mkdir build && \
    cd build && \
    \
    Rscript -e 'install.packages(c("aws.s3", "aws.ec2metadata", "ggraph", "igraph", "RPostgres", "text2vec", "tidytext", "tm", "topicmodels", "widyr", "wordcloud2", "tidyverse", "devtools", "plotly", "shiny", "leaflet", "shinydashboard", "sf", "shinycssloaders"), clean=TRUE)' && \
    \
    # Allow the run-time user to override anything just installed (e.g. with newer versions)
    chown -R dw-user:dw-user /usr/local/lib/R/site-library && \
    \
    # Cleanup temporary files
    cd .. && \
    rm -r -f build


###################################################################################################
# RStudio

FROM rv4-common-packages AS rv4-rstudio

RUN \
    # Install RStudio
    apt-get update && \
    wget -q https://download2.rstudio.org/server/bionic/amd64/rstudio-server-2023.03.0-386-amd64.deb && \
    echo "8dcc6003cce4cf41fbbc0fd2c37c343311bbcbfa377d2e168245ab329df835b5  rstudio-server-2023.03.0-386-amd64.deb" | sha256sum -c && \
    gdebi --non-interactive rstudio-server-2023.03.0-386-amd64.deb && \
    rm rstudio-server-2023.03.0-386-amd64.deb && \
    rm -rf /var/lib/apt/lists/* && \
    \
    # Configure RStudio
    R_VERSION=$(Rscript -e 'cat(paste0(getRversion()$major, ".", getRversion()$minor))') && \
    echo 'www-port=8888' >> /etc/rstudio/rserver.conf && \
    echo 'auth-none=1' >> /etc/rstudio/rserver.conf && \
    echo 'server-daemonize=0' >> /etc/rstudio/rserver.conf && \
    echo 'session-rprofile-on-resume-default=1' >> /etc/rstudio/rsession.conf && \
    echo 'session-timeout-minutes=0' >> /etc/rstudio/rsession.conf && \
    echo 'session-save-action-default=no' >> /etc/rstudio/rsession.conf && \
    echo 'CRAN=https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/cran-binary-debian-bullseye-r-'$R_VERSION'/' >> /etc/rstudio/repos.conf && \
    echo 'CRAN_1=https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/cran/' >> /etc/rstudio/repos.conf && \
    echo 'setHook("rstudio.sessionInit", function(newSession) {' > /usr/lib/R/etc/Rprofile.site && \
    echo '  if (newSession) {' >> /usr/lib/R/etc/Rprofile.site && \
    echo '      message("Welcome to RStudio [New Session]")' >> /usr/lib/R/etc/Rprofile.site && \
    echo '      readRenviron("/usr/lib/R/etc/Renviron.site")' >> /usr/lib/R/etc/Rprofile.site && \
    echo '  } else {' >> /usr/lib/R/etc/Rprofile.site && \
    echo '      message("Welcome to RStudio [Restored Session with New Credentials]")' >> /usr/lib/R/etc/Rprofile.site && \
    echo '      readRenviron("/usr/lib/R/etc/Renviron.site")' >> /usr/lib/R/etc/Rprofile.site && \
    echo '  }' >> /usr/lib/R/etc/Rprofile.site && \
    echo '}, action = "append")' >> /usr/lib/R/etc/Rprofile.site && \
    echo '' >> /usr/lib/R/etc/Rprofile.site

COPY rv4-rstudio/rstudio-start.sh /

CMD ["/rstudio-start.sh"]


###################################################################################################
# R version 4 visualisations

FROM rv4-common-packages AS rv4-visualisation

# Uses the rv4-common-packages, nothing extra required


###################################################################################################
# pgAdmin

FROM base AS pgadmin

ENV \
    PYTHONPATH=/pgadmin4 \
    PGADMIN_LISTEN_ADDRESS=0.0.0.0 \
    PGADMIN_LISTEN_PORT=8888 \
    PGADMIN_DEFAULT_EMAIL=pgadmin4@pgadmin.org \
    PGADMIN_DEFAULT_PASSWORD=test

RUN \
    apt-get update && \
    apt-get install python3 python3-pip -y --no-install-recommends && \
    rm -rf /var/lib/apt/lists/* && \
    pip3 install gunicorn pgadmin4==8.11 && \
    mkdir /pgadmin4 && \
    mkdir -p /var/lib/pgadmin && \
    chown dw-user:dw-user /var/lib/pgadmin && \
    mkdir -p  /var/log/pgadmin && \
    touch /var/log/pgadmin/pgadmin4.log && \
    chown -R dw-user:dw-user /var/log/pgadmin && \
    chmod g=u /var/lib/pgadmin

COPY pgadmin/config_local.py /usr/local/lib/python3.9/dist-packages/pgadmin4/

RUN \
    # Set preferences to not show the dashboard on startup, which (at best) makes the logs of
    # what's doing on in the database really noisy, and at worst has performance implications
    # Note that we have to actually run pgadmin4 first, and only then is it possible to set preferences
    # This is because `set-prefs` depends on rows in the SQLite preference database that, as far we
    # we can tell, only get created after pgadmin4 has run properly. We don't have a way of detecting
    # if pgadmin4 has run enough to actually create the preference rows, but it really should have in
    # 20 seconds, and we only build this Docker image occasionally
    (timeout 20s pgadmin4; exit 0) && \
    python3 /usr/local/lib/python3.9/dist-packages/pgadmin4/setup.py set-prefs pgadmin4@pgadmin.org 'dashboards:display:show_graphs=false' 'dashboards:display:show_activity=false'

COPY pgadmin/start.sh /

ENTRYPOINT ["/start.sh"]


###################################################################################################
# Remote desktop

FROM base AS remote-desktop

RUN \
    # Install gretl and packages for remote desktop
    apt-get update && \
    apt-get install -y --no-install-recommends \
        bzip2 \
        dbus-x11 \
        gnupg \
        gretl \
        gzip \
        lxqt-themes \
        nginx \
        openbox \
        procps \
        software-properties-common \
        task-lxqt-desktop \
        tigervnc-standalone-server \
        vim \
        wget && \
    \
    # Install QGIS
    wget -qO - https://qgis.org/downloads/qgis-2022.gpg.key | gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/qgis-archive.gpg --import && \
    chmod a+r /etc/apt/trusted.gpg.d/qgis-archive.gpg && \
    add-apt-repository "deb https://qgis.org/ubuntu $(lsb_release -c -s) main" && \
    apt update && \
    apt install qgis qgis-plugin-grass -y && \
    rm -rf /var/lib/apt/lists/* && \
    \
    # Install Websockify
    wget https://github.com/novnc/websockify/archive/refs/tags/v0.9.0.tar.gz && \
    tar -zxvf v0.9.0.tar.gz && \
    cd websockify-0.9.0 && \
    python3 setup.py install && \
    cd .. && \
    rm -r -f v0.9.0.tar.gz

COPY remote-desktop/index.html /webroot/index.html
COPY remote-desktop/start.sh remote-desktop/nginx.conf remote-desktop/org.qgis.qgis.desktop remote-desktop/gretl.desktop /
COPY remote-desktop/lxqt /etc/xdg/lxqt

RUN \
    gzip -c /webroot/index.html > /webroot/index.html.gz && \
    touch /var/run/nginx.pid && \
    chown dw-user:dw-user /var/run/nginx.pid

CMD ["/start.sh"]


###################################################################################################
# Syncs files to and from each user's areas in S3 ("Your files")

FROM base AS s3sync

RUN \
    # Try to disable ipv6 AAAA lookups, which our DNS rewrite proxy doesn't support
    # Not 100% sure that this really does have an effect
    echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf

RUN \
    apt update && \
    apt install -y sudo python3-pip && \
    rm -rf /var/lib/apt/lists/*

COPY s3sync/requirements.txt /app/

RUN \
    pip3 install \
        -r /app/requirements.txt

COPY s3sync/start.sh /

CMD ["/start.sh"]


###################################################################################################
# Collects metrics from tools

FROM base AS metrics

RUN \
    apt-get update && \
    apt-get install python3 python3-pip -y --no-install-recommends && \
    rm -rf /var/lib/apt/lists/* && \
	pip3 install \
		aiohttp==3.10.10

COPY metrics/metrics.py /

CMD ["python3", "/metrics.py"]

USER dw-user
