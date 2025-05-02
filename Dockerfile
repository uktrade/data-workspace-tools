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
# │   ├── python-vscode
# │   ├── python-visualisation
# │   └── python-pgadmin
# ├── rv4
# │   ├── rv4-cran-binary-mirror
# │   └── rv4-common-packages
# │       ├── rv4-rstudio
# │       └── rv4-visualisation
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
    # Install and configure locales, fonts, sudo, and the user and group to run tools under
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
        git \
        git-lfs \
        git-man \
        gnupg2 \
        fonts-roboto \
        fonts-recommended \
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
    rm -rf /var/lib/apt/lists/*

RUN \
    mkdir -p "$CONDA_DIR" && \
    curl https://repo.anaconda.com/miniconda/Miniconda3-py39_24.11.1-0-Linux-x86_64.sh --output /root/miniconda.sh && \
    echo "3ea8373098d72140e08aac9217822b047ec094eb457e7f73945af7c6f68bf6f5 /root/miniconda.sh" | sha256sum --check --status && \
    bash /root/miniconda.sh -f -b -p "$CONDA_DIR" && \
    echo 'channels:' > /opt/conda/.condarc && \
    echo '  - https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/conda-forge/' >> /opt/conda/.condarc && \
    echo '  - https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/anaconda/' >> /opt/conda/.condarc && \
    echo 'channel_alias: https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/' >> /opt/conda/.condarc && \
    echo 'allow_other_channels: false' >> /opt/conda/.condarc && \
    echo 'auto_update_conda: false' >> /opt/conda/.condarc && \
    echo 'always_yes: true' >> /opt/conda/.condarc && \
    echo 'show_channel_urls: true' >> /opt/conda/.condarc && \
    \
    echo '[global]' > /etc/pip.conf && \
    echo 'index-url = https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/pypi/' >> /etc/pip.conf && \
    echo 'extra-index-url = https://s3-eu-west-2.amazonaws.com/jupyter.notebook.uktrade.io/shared/ddat_packages/pypi/' >> /etc/pip.conf && \
    echo 'no-cache-dir = false' >> /etc/pip.conf && \
    # Activate conda when launching a bash login shell
    echo "conda activate base" >> /etc/profile && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    # Install conda's default solver (which strangely doesn't seem to get installed by default)
    conda install conda-libmamba-solver --name base && \
    # Install git filter repo so removal of data is a little easier
    conda install git-filter-repo --name base && \
    #Seem to lose less when inside the conda env so needs installing here
    conda install less --name base && \
    # Seems to need this run in order to initialise LFS
    git lfs install

# Activate conda for the CMD of any Docker stage that derives from this one
ENTRYPOINT ["/opt/conda/bin/conda", "run", "--no-capture-output", "--name", "base"]

# Activate conda for subsequent RUN statements
SHELL ["/opt/conda/bin/conda", "run", "--no-capture-output", "--name", "base", "/bin/bash", "-c"]

COPY \
    python/requirements.txt /root/

# Helper script to create index html for Gitlab private python package index packages
COPY \
    private_package_index/create_index_html.py /

# Install Python packages via conda which makes them available to users, and avoids conflicts/
# errors/warnings with Debian Python packages
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
COPY python-theia/vscode_postgres.theia /root/plugins/vscode_postgres.theia

RUN \
    cd /root && \
    curl -o- -L https://yarnpkg.com/install.sh | bash && \
	yarn install && \
	theia build && \
	theia download:plugins && \
	yarn cache clean && \
	find /root -type d -exec chmod 755 {} + && \
	chmod -R +r /root && \
    \
	mkdir /tmp/.yarn-cache && \
	chown dw-user:dw-user /tmp/.yarn-cache && \
	touch /root/yarn-error.log && \
	chown dw-user:dw-user /root/yarn-error.log

COPY python-theia/start.sh /start.sh

CMD ["/start.sh"]


###################################################################################################
# VS Code

FROM python AS python-vscode

# Install VS Code (via code-server) and extensions
RUN \
    curl -fsSL https://code-server.dev/install.sh | sh -s -- --version 4.96.2 && \
    code-server --extensions-dir /etc/code-server-extensions --user-data-dir /home/dw-user/.vscode --install-extension ms-python.python@2024.22.1 && \
    code-server --extensions-dir /etc/code-server-extensions --user-data-dir /home/dw-user/.vscode --install-extension ms-toolsai.jupyter@2024.11.0 && \
    code-server --extensions-dir /etc/code-server-extensions --user-data-dir /home/dw-user/.vscode --install-extension ckolkman.vscode-postgres@1.4.3 && \
    rm -r -f /home/dw-user/.vscode

# VS Code in the browser make requests subdomains of vscode-cdn.net... but these are rewritten
# by service workers and handled internally. So to allow us to still have quite a locked down CSP,
# we modify the code to always reqeust vscode-cdn.invalid. We can then have *.vscode-cdn.invalid in
# the CSP, but because these domains cannot actually exist, it doesn't meaningfully increase the
# risk of data leakage
RUN \
    grep -rlZ vscode-cdn.net /usr/lib/code-server | xargs -0 sed -i 's/vscode-cdn.net/vscode-cdn.invalid/g'

# The PostgreSQL extension for VS Code at https://github.com/Borvik/vscode-postgres doesn't have
# a built-in way of automatically setting up a connection. However, we can monkey patch it to add
# one, and since it seems to use libpq under the hood, it will automatically take credentials
# from environment variables
RUN \
    echo -e "\nexports.activate = (context) => {context.globalState.update('postgresql.connections',{'00000000-0000-4000-8000-000000000000':{label:'datasets',hasPassword:false,ssl:true,certPath:'/certs/rds-global-bundle.pem',database:'public_datasets_1',host:'',user:'',port:''}});activate(context);};" >> /etc/code-server-extensions/ckolkman.vscode-postgres-1.4.3-universal/out/extension.js

COPY python-vscode/merge-settings.py /merge-settings.py
COPY python-vscode/settings.json /etc/code-server-defaults/settings.json
COPY python-vscode/start.sh /start.sh

CMD ["/start.sh"]


###################################################################################################
# Base for Python visualisations

FROM python AS python-visualisation

# Uses the python base, nothing extra required


###################################################################################################
# pgAdmin

FROM python AS python-pgadmin

ENV \
    PYTHONPATH=/pgadmin4 \
    PGADMIN_LISTEN_ADDRESS=0.0.0.0 \
    PGADMIN_LISTEN_PORT=8888 \
    PGADMIN_DEFAULT_EMAIL=pgadmin4@pgadmin.org \
    PGADMIN_DEFAULT_PASSWORD=test

# pgadmin4 is not compatible with recent versions of pip, so we have to downgrade
RUN \
    pip3 install 'pip<24.0' && \
    pip3 install gunicorn pgadmin4==8.11 && \
    mkdir /pgadmin4 && \
    mkdir -p /var/lib/pgadmin && \
    chown dw-user:dw-user /var/lib/pgadmin && \
    mkdir -p  /var/log/pgadmin && \
    touch /var/log/pgadmin/pgadmin4.log && \
    chown -R dw-user:dw-user /var/log/pgadmin && \
    chmod g=u /var/lib/pgadmin

COPY python-pgadmin/config_local.py /opt/conda/lib/python3.9/site-packages/pgadmin4/

RUN \
    # Set preferences to:
    # - not show the dashboard or activity on startup, which (at best) makes the logs of what's
    #   doing on in the database really noisy, and at worst has performance implications
    # - also not show roles, which for us doesn't really have a use case, and also can return
    #   thousands of roles, which can have performance implictions
    # - and not show tablespaces, which we don't need for users
    # Note that we have to actually run pgadmin4 first, and only then is it possible to set preferences
    # This is because `set-prefs` depends on rows in the SQLite preference database that, as far we
    # we can tell, only get created after pgadmin4 has run properly. We don't have a way of detecting
    # if pgadmin4 has run enough to actually create the preference rows, but it really should have in
    # 20 seconds, and we only build this Docker image occasionally
    (timeout 20s pgadmin4; exit 0) && \
    python3 /opt/conda/lib/python3.9/site-packages/pgadmin4/setup.py set-prefs pgadmin4@pgadmin.org 'dashboards:display:show_graphs=false' 'dashboards:display:show_activity=false' 'browser:node:show_node_role=false' 'browser:node:show_node_tablespace=false'

RUN \
    # This query fetches all roles on the server when starting up pgAdmin/running queries, even
    # though showing roles is disabled in the UI, and it is extremely unperformant. The easiest
    # workaround to get things going seems to be to add a LIMIT 0 to the end of it
    echo " LIMIT 0" >> /opt/conda/lib/python3.9/site-packages/pgadmin4/pgadmin/browser/server_groups/servers/roles/templates/roles/sql/default/nodes.sql

COPY python-pgadmin/start.sh /

CMD ["/start.sh"]


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
    # Install commonly needed fonts
    apt-get update && \
    apt-get install -y --no-install-recommends \
        fonts-roboto \
        fonts-recommended && \
    rm -rf /var/lib/apt/lists/* && \
    # Build in new directory to make cleanup easier
    mkdir build && \
    cd build && \
    \
    Rscript -e 'install.packages(c("aws.s3", "aws.ec2metadata", "ggraph", "igraph", "RPostgres", "text2vec", "tidytext", "tm", "topicmodels", "widyr", "wordcloud2", "tidyverse", "devtools", "plotly", "shiny", "leaflet", "shinydashboard", "sf", "shinycssloaders", "rmarkdown", "markdown"), clean=TRUE)' && \
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
COPY rv4-rstudio/dw-rstudio-in-rstudio /usr/bin/dw-rstudio-in-rstudio

CMD ["/rstudio-start.sh"]


###################################################################################################
# R version 4 visualisations

FROM rv4-common-packages AS rv4-visualisation

# Uses the rv4-common-packages, nothing extra required


###################################################################################################
# Remote desktop

FROM base AS remote-desktop

RUN \
    # Install gretl and packages for remote desktop
    apt-get update && \
    apt-get install -y --no-install-recommends \
        bzip2 \
        dbus-x11 \
        fonts-roboto \
        fonts-recommended \
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
#
# We _could_ inherit from the Python base layer, and this might be nicer for maintainability, but
# this is a sidecar image, and so prefer to keep it small so it doesn't slow down loading of tools.

FROM base AS s3sync

RUN \
    # Try to disable ipv6 AAAA lookups, which our DNS rewrite proxy doesn't support
    # Not 100% sure that this really does have an effect
    echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf

RUN \
    apt update && \
    apt install -y sudo python3-pip python3-venv && \
    rm -rf /var/lib/apt/lists/* && \
    python3 -m venv /venv

COPY s3sync/requirements.txt /app/

RUN \
    . /venv/bin/activate && \
    pip3 install \
        -r /app/requirements.txt

COPY s3sync/start.sh /

CMD . /venv/bin/activate && /start.sh


###################################################################################################
# Collects metrics from tools
#
# We _could_ inherit from the Python base layer, and this might be nicer for maintainability, but
# this is a sidecar image, and so prefer to keep it small so it doesn't slow down loading of tools.

FROM base AS metrics

RUN \
    apt update && \
    apt install -y sudo python3-pip python3-venv && \
    rm -rf /var/lib/apt/lists/* && \
    python3 -m venv /venv && \
    . /venv/bin/activate && \
	pip3 install \
		aiohttp==3.10.10

COPY metrics/metrics.py /

CMD . /venv/bin/activate && python3 /metrics.py

USER dw-user
