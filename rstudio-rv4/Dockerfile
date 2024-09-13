FROM debian:bullseye

RUN \
	echo "deb [trusted=yes] https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/debian/ bullseye main" > /etc/apt/sources.list && \
	echo "deb [trusted=yes] https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/debian-security/ bullseye-security main" >> /etc/apt/sources.list && \
	echo "deb [trusted=yes] https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/debian/ bullseye-updates main" >> /etc/apt/sources.list && \
	echo "Acquire{Check-Valid-Until false; Retries 10;}" >> /etc/apt/apt.conf && \
    echo "Acquire { https::Verify-Peer false }" > /etc/apt/apt.conf.d/99verify-peer.conf && \
    apt-get update && \
	apt-get install -y --no-install-recommends \
		locales ca-certificates && \
    rm /etc/apt/apt.conf.d/99verify-peer.conf && \
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
	LANGUAGE=en_US.UTF-8

COPY rstudio/exploretiva /exploretiva

RUN \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		dirmngr \
		gnupg2 && \
	echo "deb http://cran.ma.imperial.ac.uk/bin/linux/debian bullseye-cran40/" >> /etc/apt/sources.list && \
	echo "deb-src http://cran.ma.imperial.ac.uk/bin/linux/debian bullseye-cran40/" >> /etc/apt/sources.list && \
	until apt-key adv --keyserver keyserver.ubuntu.com --recv-key '95C0FAF38DB3CCAD0C080A7BDC78B2DDEABC47B7'; do sleep 10; done && \
	apt-get clean -y && \
	apt-get autoremove -y && \
	apt-get autoclean -y && \
	rm -rf /tmp/* && \
	rm -rf /var/lib/apt/lists/* && \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		apt-src \
		gdebi-core \
		gfortran \
		git \
		libgit2-dev \
		libgsl-dev \
		libxml2-dev \
		libpq-dev \
		libgdal-dev \
		lmodern \
		procps \
		ssh \
		texlive \
		texlive-latex-extra \
		git-man \
		libcairo2-dev \
		libfontconfig1-dev \
		libjq-dev \
		libmagick++-dev \
		libnode-dev \
		libprotobuf-dev \
		libprotobuf-dev \
		libssl-dev \
		libudunits2-dev \
		libv8-dev \
		protobuf-compiler \
		libfribidi-dev \
		libharfbuzz-dev \
		man-db \
		vim \
		emacs \
		wget && \
	apt-src update && \
	apt-src --build install \
		r-base-dev=4.4.0-2~bullseyecran.0 \
		r-base=4.4.0-2~bullseyecran.0 \
		r-recommended=4.4.0-2~bullseyecran.0 && \
	wget -q https://download2.rstudio.org/server/bionic/amd64/rstudio-server-2023.03.0-386-amd64.deb && \
	echo "8dcc6003cce4cf41fbbc0fd2c37c343311bbcbfa377d2e168245ab329df835b5  rstudio-server-2023.03.0-386-amd64.deb" | sha256sum -c && \
	gdebi --non-interactive rstudio-server-2023.03.0-386-amd64.deb && \
	rm rstudio-server-2023.03.0-386-amd64.deb && \
	apt-get remove --purge -y \
		dirmngr \
		gdebi-core \
		gnupg2 \
		wget && \
	apt-get clean -y && \
	apt-get autoremove -y && \
	apt-get autoclean -y && \
	rm -rf /tmp/* && \
	rm -rf /var/lib/apt/lists/*

RUN \
	# Remove the last line from sources: the CRAN debian repo that has R itself, which we don't mirror
	sed -i '$d' /etc/apt/sources.list && \
	echo 'www-port=8888' >> /etc/rstudio/rserver.conf && \
	echo 'auth-none=1' >> /etc/rstudio/rserver.conf && \
	echo 'server-daemonize=0' >> /etc/rstudio/rserver.conf && \
	echo 'setHook("rstudio.sessionInit", function(newSession) {' > /usr/lib/R/etc/Rprofile.site && \
	echo '	if (newSession) {' >> /usr/lib/R/etc/Rprofile.site && \
	echo '		message("Welcome to RStudio [New Session]")' >> /usr/lib/R/etc/Rprofile.site && \
	echo '		readRenviron("/usr/lib/R/etc/Renviron.site")' >> /usr/lib/R/etc/Rprofile.site && \
	echo '  } else {' >> /usr/lib/R/etc/Rprofile.site && \
	echo '		message("Welcome to RStudio [Restored Session with New Credentials]")' >> /usr/lib/R/etc/Rprofile.site && \
	echo '		readRenviron("/usr/lib/R/etc/Renviron.site")' >> /usr/lib/R/etc/Rprofile.site && \
	echo '	}' >> /usr/lib/R/etc/Rprofile.site && \
	echo '}, action = "append")' >> /usr/lib/R/etc/Rprofile.site && \
	echo '' >> /usr/lib/R/etc/Rprofile.site && \
	echo 'local({' >> /usr/lib/R/etc/Rprofile.site && \
	echo '  r = getOption("repos")' >> /usr/lib/R/etc/Rprofile.site && \
	echo '  r["CRAN"] = "https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/cran-binary-rv4/"' >> /usr/lib/R/etc/Rprofile.site && \
	echo '  r["CRAN_1"] = "https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/cran/"' >> /usr/lib/R/etc/Rprofile.site && \
	echo '  options(repos = r)' >> /usr/lib/R/etc/Rprofile.site && \
	echo '})' >> /usr/lib/R/etc/Rprofile.site && \
	echo '' >> /usr/lib/R/etc/Rprofile.site && \
	echo 'CRAN=https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/cran-binary-rv4/' >> /etc/rstudio/repos.conf && \
	echo 'CRAN_1=https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/cran/' >> /etc/rstudio/repos.conf && \
	echo 'session-rprofile-on-resume-default=1' >> /etc/rstudio/rsession.conf && \
	echo 'session-timeout-minutes=0' >> /etc/rstudio/rsession.conf && \
	echo 'session-save-action-default=no' >> /etc/rstudio/rsession.conf && \
	Rscript -e 'install.packages("/exploretiva", repos=NULL, type="source")' && \
	Rscript -e 'install.packages(c("aws.s3", "aws.ec2metadata", "ggraph", "igraph", "RPostgres", "text2vec", "tidytext", "tm", "topicmodels", "widyr", "wordcloud2", "tidyverse", "devtools", "plotly", "shiny", "leaflet", "shinydashboard", "sf", "shinycssloaders"), repos=c("https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/cran-binary-rv4/", "https://s3-eu-west-2.amazonaws.com/mirrors.notebook.uktrade.io/cran/"), clean=TRUE)'

COPY rstudio-rv4/rstudio-start.sh /

ENV \
	USER=rstudio

RUN \
	addgroup --system --gid 4356 rstudio && \
	adduser --disabled-password --gecos '' --ingroup rstudio --uid 4357 rstudio && \
	chown -R rstudio:rstudio /usr/local/lib/R/site-library && \
	# Avoids errors when installing Java
	mkdir -p /usr/share/man/man1mkdir -p /usr/share/man/man1 && \
	echo "root ALL=(ALL:ALL) ALL" > /etc/sudoers && \
	echo "rstudio ALL=NOPASSWD:/usr/bin/dw-install" >> /etc/sudoers && \
	echo 'PS1="\[\033[01;34m\]\w\[\033[00m\]\$ "' >> /etc/bash.bashrc && \
	echo 'export PATH="/home/rstudio/.local/bin:$PATH"' >> /etc/bash.bashrc && \
	rm /home/rstudio/.bashrc

COPY dw-install /usr/bin/dw-install

CMD ["/rstudio-start.sh"]
