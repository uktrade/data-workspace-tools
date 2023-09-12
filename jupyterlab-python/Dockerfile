FROM debian:bullseye

RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        locales && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen en_US.utf8 && \
    apt-get clean -y && \
    apt-get autoremove -y && \
    apt-get autoclean -y && \
    rm -rf /tmp/* && \
    rm -rf /var/lib/apt/lists/*

ENV \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LD_LIBRARY_PATH=/lib \
    CONDA_DIR=/opt/conda

ENV \
    PATH="$CONDA_DIR/bin:$PATH"

RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        dirmngr \
        gnupg2 \
        libfreetype-dev \
        ssh \
        vim \
        emacs \
        wget && \
    echo "deb https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/debian/ bullseye main" > /etc/apt/sources.list && \
    echo "deb https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/debian/ bullseye-updates main" >> /etc/apt/sources.list && \
    echo "Acquire{Check-Valid-Until false; Retries 10;}" >> /etc/apt/apt.conf && \
    until apt-key adv --keyserver pgp.mit.edu --recv-key 'E19F5F87128899B192B1A2C2AD5F960A256A04AF'; do sleep 10; done && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        git \
        git-lfs \
        git-man \
        libxext6 \
        libxrender1 \
        openssl \
        openssh-client \
        texlive-xetex \
        texlive-plain-generic \
        texlive-fonts-recommended \
        fonts-dejavu-core \
        sudo \
        man-db \
        tini && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3 1 && \
    groupadd -g 4356 jovyan && \
    useradd -u 4357 jovyan -g jovyan -m && \
    echo "root ALL=(ALL:ALL) ALL" > /etc/sudoers && \
    echo "jovyan ALL=NOPASSWD:/usr/bin/dw-install" >> /etc/sudoers && \
    wget -q -O - https://deb.nodesource.com/setup_14.x | bash  && \
    apt-get install -y nodejs && \
    apt-get remove --purge -y \
        wget && \
    apt-get clean -y && \
    apt-get autoremove -y && \
    apt-get autoclean -y && \
    rm -rf /tmp/* && \
    rm -rf /var/lib/apt/lists/* && \
    # Remove the last line from sources: the CRAN debian repo that has R itself, which we don't mirror
    sed -i '$d' /etc/apt/sources.list && \
    # Avoids errors when installing Java
    mkdir -p /usr/share/man/man1mkdir -p /usr/share/man/man1

COPY requirements.txt python-setup.sh /root/

RUN \
       mkdir -p "$CONDA_DIR" && \
       curl https://repo.anaconda.com/miniconda/Miniconda3-py39_4.11.0-Linux-x86_64.sh --output /root/miniconda.sh && \
       echo "4ee9c3aa53329cd7a63b49877c0babb49b19b7e5af29807b793a76bdb1d362b4 /root/miniconda.sh" | sha256sum --check --status && \
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
    chown -R jovyan:jovyan /usr/local && \
    chown -R jovyan:jovyan /opt/conda

COPY jupyterlab-python/jupyter_notebook_config.py /etc/jupyter/jupyter_notebook_config.py

ENTRYPOINT ["tini", "-g", "--"]

WORKDIR /home/jovyan

# The ipython history database does not play well with mobius3, surfacing
# occasional errors like "attempt to write a readonly database", so we store
# it where mobius3 does not sync
ENV IPYTHONDIR=/tmp/ipython

ENV \
    JUPYTER_CONFIG_DIR=/home/jovyan/.jupyterlab_python \
    JUPYTER_DATA_DIR=/tmp/jupyterlab_python \
    JUPYTER_RUNTIME_DIR=/tmp/jupyterlab_python/runtime

# The home directory in Data Workspace is a volume that is empty by default,
# so there is no ~/.bashrc. We delete the one here to make testing locally
# more like production
RUN \
    echo 'PS1="\w\\\\$ \[$(tput sgr0)\]"' >> /etc/bash.bashrc && \
    rm /home/jovyan/.bashrc

COPY dw-install /usr/bin/dw-install
COPY glfsm /usr/bin/glfsm
COPY jupyterlab-python/start.sh /

CMD ["/start.sh"]
