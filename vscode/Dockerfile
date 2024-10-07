FROM codercom/code-server:latest

USER root

RUN \
echo "root ALL=(ALL:ALL) ALL" > /etc/sudoers && \
echo "coder ALL=NOPASSWD:/usr/bin/dw-install" >> /etc/sudoers

RUN \
apt-get update && \
apt-get install -y --no-install-recommends locales && \
echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen && \
locale-gen en_GB.utf8 && \
rm -rf /var/lib/apt/lists/*

ENV \
LC_ALL=en_GB.UTF-8 \
LANG=en_GB.UTF-8 \
LANGUAGE=en_GB.UTF-8 \
CONDA_DIR=/opt/conda

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
 
RUN apt-get update && \
apt-get install -y \
build-essential \
git \
git-lfs \
curl \
man-db \
vim \
emacs \
procps \
sudo \
pkg-config \
jq \
libsecret-1-dev \
postgresql-client && \
rm -rf /var/lib/apt/lists/*

RUN \
mkdir -p "$CONDA_DIR" && \
curl https://repo.anaconda.com/miniconda/Miniconda3-py39_24.7.1-0-Linux-x86_64.sh --output /root/miniconda.sh && \
echo "2006a61abc8b4fd04de5eb92620e1f72bada713cc84b5b4899463095e1210556 /root/miniconda.sh" | sha256sum --check --status && \
bash /root/miniconda.sh -f -b -p "$CONDA_DIR" && \
echo 'channels:' > /opt/conda/.condarc && \
echo '  - https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/conda-forge/' >> /opt/conda/.condarc && \
echo '  - https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/anaconda/' >> /opt/conda/.condarc && \
echo 'allow_other_channels: false' >> /opt/conda/.condarc && \
echo 'auto_update_conda: false' >> /opt/conda/.condarc && \
echo 'always_yes: true' >> /opt/conda/.condarc && \
echo 'show_channel_urls: true' >> /opt/conda/.condarc && \
chown -R coder:coder /opt/conda

RUN \
echo '[global]' > /etc/pip.conf && \
echo 'index-url = https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/pypi/' >> /etc/pip.conf && \
echo 'no-cache-dir = false' >> /etc/pip.conf

COPY requirements.txt /root/requirements.txt
RUN \
/opt/conda/bin/python3 -m pip install --upgrade pip setuptools wheel && \
/opt/conda/bin/python3 -m pip install -r /root/requirements.txt && \
update-alternatives --install /opt/conda/bin/python python /opt/conda/bin/python3 1

RUN \
/opt/conda/condabin/conda install -y conda-libmamba-solver && \
/opt/conda/condabin/conda config --set solver libmamba

RUN \
/opt/conda/condabin/conda install -y -c conda-forge -c r \
r-base \
r-irkernel \
r-essentials \
r-aws.s3 \
r-aws.ec2metadata \
r-ggraph \
r-igraph \
r-rpostgres \
r-text2vec \
r-tidytext \
r-tm \
r-topicmodels \
r-widyr \
r-wordcloud2 \
r-tidyverse \
r-devtools \
r-plotly \
r-shiny \
r-leaflet \
r-shinydashboard \
r-sf \
r-shinycssloaders \
r-languageserver && \
/opt/conda/condabin/conda clean -afy && \
mkdir -p /usr/lib/R/etc/ && \
echo 'local({' >> /usr/lib/R/etc/Rprofile.site && \
echo '  r = getOption("repos")' >> /usr/lib/R/etc/Rprofile.site && \
echo '  r["CRAN"] = "https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/cran-binary-rv4/"' >> /usr/lib/R/etc/Rprofile.site && \
echo '  r["CRAN_1"] = "https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/cran/"' >> /usr/lib/R/etc/Rprofile.site && \
echo '  options(repos = r)' >> /usr/lib/R/etc/Rprofile.site && \
echo '})' >> /usr/lib/R/etc/Rprofile.site && \
echo '' >> /usr/lib/R/etc/Rprofile.site

RUN mkdir /certs
COPY rds-global-bundle.pem /certs/rds-global-bundle.pem

COPY dw-install glfsm /usr/bin/

COPY vscode/config.yaml vscode/start.sh vscode/settings.json /opt/code-server/
RUN \
chmod +x /opt/code-server/start.sh && \
chown -R coder:coder /opt/code-server

RUN \
echo 'PS1="\u@data-workspace:\w$ "' >> /etc/bash.bashrc && \
echo 'export PATH="$CONDA_DIR/bin:$PATH"' >> /etc/profile && \
echo 'conda init' >> /etc/profile && \
ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
rm /home/coder/.bashrc && \
rm /home/coder/.profile

##### extension: marketplace auto installs
RUN \
code-server \
--install-extension ms-toolsai.jupyter \
--install-extension ms-toolsai.jupyter-renderers \
--install-extension ms-python.python \
--install-extension reditorsupport.r \
--install-extension ckolkman.vscode-postgres \
--extensions-dir /usr/lib/code-server/lib/vscode/extensions/

##### extensions: marketplace manual installs
RUN \
curl \
-o /opt/code-server/data-wrangler-latest.vsix \
-L "https://ms-toolsai.gallery.vsassets.io/_apis/public/gallery/publisher/ms-toolsai/extension/datawrangler/latest/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage" && \
code-server --install-extension /opt/code-server/data-wrangler-latest.vsix \
--extensions-dir /usr/lib/code-server/lib/vscode/extensions/

RUN \
curl \
-o /opt/code-server/arangodb-latest.vsix \
-L "https://monotykamary.gallery.vsassets.io/_apis/public/gallery/publisher/monotykamary/extension/vscode-aql/latest/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage" && \
code-server --install-extension /opt/code-server/arangodb-latest.vsix \
--extensions-dir /usr/lib/code-server/lib/vscode/extensions/

##### extensions: available but not installed
RUN \
curl \
-o /opt/code-server/vim-latest.vsix \
-L "https://vscodevim.gallery.vsassets.io/_apis/public/gallery/publisher/vscodevim/extension/vim/latest/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"

##### override code-server entrypoint
##### https://github.com/coder/code-server/blob/main/ci/release-image/Dockerfile
##### https://github.com/coder/code-server/blob/main/ci/release-image/entrypoint.sh
EXPOSE 8888
ENTRYPOINT ["/usr/bin/env"]
CMD ["/opt/code-server/start.sh"]
