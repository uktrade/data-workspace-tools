# Data Workspace Tools

Repository for the Dockerfiles for Data Workspace on-demand tools and related components. Merging the various Dockerfiles to a [single multi-stage Dockerfile](./Dockerfile) is in progress.

With some exceptions, they can be built and pushed using https://jenkins.ci.uktrade.digital/job/data-workspace-tools/


## What makes a "tool"?

Any application that can run in Docker and listen on HTTP on port 8888. Data Workspace starts each tool up, and then the [Data Workspace proxy](https://github.com/uktrade/data-workspace-frontend/blob/master/dataworkspace/proxy.py) routes incoming requests from the user to the tool. Each tool runs under an IAM role specific to each user, which is used to control access to the user's folder(s) in the "notebooks" S3 bucket. In addition, Data Workspace sets various environment variables for credentials, for example for the Data Workspace datasets database.


## Linux-level user

Each tool runs under the same non-root user, dw-user, that is a member of the dw-user group. The user ID is fixed as 4356 and the group ID as 4357. These are fixed to allow the s3sync sidecar container to run as the same user to continually sync local files in /home/dw-user with the user's area in an S3 bucket.

Typically tools run a startup script as root to perform setup tasks that require root access, but then run the tool proper under dw-user.


## Mirrors

A feature of Data Workspace tools is their isolation from the internet. To still allow install of packages without internet access, we mirror Debian, PyPI, conda-forge, anaconda, and CRAN to our own S3 bucket that is accessible from tools, and the tools are configured in the [Dockerfile](./Dockerfile) to pull packages from this bucket. The mirroring is done by the [Sync\*MirrorPipelines in data-flow](https://github.com/uktrade/data-flow/blob/main/dags/data_infrastructure/split_mirror_sync_pipelines.py).

In addition, the bucket contains what we call the "CRAN binary mirror" that contains a subset of CRAN packages that have been pre-compiled because some packages are very slow to compile. The code for the compiling is in the rv4-cran-binary-mirror stage of the Dockerfile, and run by the [SyncCranBinaryMirrorPipeline in data-flow](https://github.com/uktrade/data-flow/blob/main/dags/data_infrastructure/mirror_cran_binary.py).


## Sudo

(Passwordless) sudo is allowed only for the "dw-install" script that allows the dw-user to install Debian packages from our Debian mirror.


## Hierarchy of stages

The [Dockerfile](./Dockerfile) is a multi-stage Dockerfile, where each stage is a tool, related component, or a stage that contains files shared between multiple tools or related components. This allows Dockerfile code to be shared without duplication, helping maintain consistency.

- **base**

  Common packages, tools, and configuration for all tools and visualisations.

  - **python** - Common Python packages for all python-based tools and visualisations.

    - **python-jupyterlab** - A light layer with some JupyterLab-specific configuration.

    - **python-theia** - Adds Theia to the python stage.

    - **python-visualisation** - Base image for Python-based visualisations. This currently does not add anything to the python stage.

   - **rv4** - R version 4, related packages, and configuration.

     - **rv4-cran-binary-mirror** - The code to populate our mirror that contains a compiled chosen subset of CRAN packages for R version 4.

     - **rv4-common-packages** - Adds a set of frequently-used packages to the rv4 stage.

       - **rv4-rstudio** - RStudio running R version 4.

       - **rv4-visualisation** - Base image for R version 4 based visualisations. This currently does not add anything to the rv4-common-packages stage.

   - **pgadmin** - Runs [pgAdmin](https://www.pgadmin.org/), used to expore the datasets database and to run SQL-queries.

   - **remote-desktop** - A basic remote desktop setup that runs [gretl](https://gretl.sourceforge.net/) and [QGIS](https://qgis.org/).

   - **s3sync** - A sidecar container running [mobius3](https://github.com/uktrade/mobius3) that syncs files to and from the S3 "Your Files" area for each user.

   - **metrics** - A sidecar container that extract basic metrics for the tools, fetched by our internal Prometheus instance to allow us to shut down inactive tools. This was setup before we could get metrics in CloudWatch for tasks that were not part of services.
