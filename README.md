# Data Workspace Tools

Repository for the Dockerfiles for Data Workspace on-demand tools and related components. Merging the various Dockerfiles to a [single multi-stage Dockerfile](./Dockerfile) is in progress.

With some exceptions, they can be built and pushed using https://jenkins.ci.uktrade.digital/job/data-workspace-tools/


## What makes a "tool"?

Any application that can run in Docker and listen on HTTP on port 8888. Data Workspace starts each tool up, and then the [Data Workspace proxy](https://github.com/uktrade/data-workspace-frontend/blob/master/dataworkspace/proxy.py) routes incoming requests from the user to the tool. Each tool runs under an IAM role specific to each user, which is used to control access to the user's folder(s) in the "notebooks" S3 bucket. In addition, Data Workspace sets various environment variables for credentials, for example the Data Workspace datasets database.


## Linux-level user

Each tool runs under the same non-root user, dw-user, that is a member of the dw-user group. The user ID is fixed as 4356 and the group ID as 4357. These are fixed to allow the s3sync sidecar container to run as the same user and to continually sync with the user's area in an S3 bucket.

Typically tools run a startup script as root to perform setup tasks that require root access, but then run the tool proper under dw-user.


## Sudo

(Passwordless) sudo is allowed only for the "dw-install" script that allows users to install Debian packages from our Debian mirror.


## Hierarchy of stages

The [Dockerfile](./Dockerfile) is a multi-stage Dockerfile, where each stage is a tool, related component, or a stage that contains files shared between multiple tools or related components. This allows Dockerfile code to be shared without duplication, helping maintain consistency.

- [base](./base/)

  - [python](./python/)

    - [python-jupyterLab](./python-jupyterlab/)

    - python-theia

    - python-visualisation

   - rv4

     - [rv4-cran-binary-mirror](./rv4-cran-binary-mirror/)

     - rv4-common-packages

       - [rv4-rstudio](./rv4-rstudio/)

       - rv4-visualisation

   - [pgadmin](./pgadmin/)

   - [remote-desktop](./remote-desktop/)

   - [s3sync](./s3sync/)

   - [metrics](./metrics/)
