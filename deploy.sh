#!/usr/bin/env bash
# requirements:
# - login to aws
# - login to aws ecr docker

set -e

if [[ -z "${AWS_PROFILE}" ]]; then
  echo "You must set the AWS_PROFILE environment variable to the name of your profile. Often this is data-infrastructure-prod."
  exit 1
else
  echo "Using AWS profile $AWS_PROFILE"
fi

if [ "$#" -ne 2 ]; then
    echo "Expected two arguments, env and tool"
    echo "Usage: AWS_PROFILE=$AWS_PROFILE $0 <env> <tool>"
    exit 1
fi

if [ "$1" == "dev" ]; then
  environment=analysisworkspace-dev
elif [ "$1" == "staging" ]; then
  environment=data-workspace-staging
elif [ "$1" == "prod" ]; then
  environment=jupyterhub
else
  echo "First argument not recognised - valid args are 'dev', 'staging' and 'prod'."
  exit 1
fi

if [ "$2" == "python-jupyterlab" ]; then
  tool=python-jupyterlab
  tag=master
  image=jupyterlab-python
elif [ "$2" == "python-theia" ]; then
  tool=python-theia
  tag=master
  image=theia
elif [ "$2" == "python-vscode" ]; then
  tool=python-vscode
  tag=master
  image=vscode
elif [ "$2" == "python-visualisation" ]; then
  tool=python-visualisation
  tag=python
  image=visualisation-base
elif [ "$2" == "python-pgadmin" ]; then
  tool=python-pgadmin
  tag=master
  image=pgadmin
elif [ "$2" == "rv4-cran-binary-mirror" ]; then
  tool=rv4-cran-binary-mirror
  tag=master
  image=mirrors-sync-cran-binary-rv4
elif [ "$2" == "rv4-rstudio" ]; then
  tool=rv4-rstudio
  tag=master
  image=rstudio-rv4
elif [ "$2" == "rv4-visualisation" ]; then
  tool=rv4-visualisation
  tag=rv4
  image=visualisation-base
elif [ "$2" == "remote-desktop" ]; then
  tool=remote-desktop
  tag=master
  image=remotedesktop
elif [ "$2" == "s3sync" ]; then
  tool=s3sync
  tag=master
  image=jupyterlab-python
elif [ "$2" == "metrics" ]; then
  tool=metrics
  tag=master
  image=jupyterlab-python
else
  echo "Second argument not recognised - valid args are:
  'python-jupyterlab',
  'python-theia',
  'python-vscode',
  'python-visualisation',
  'python-pgadmin',
  'rv4-cran-binary-mirror',
  'rv4-rstudio',
  'rv4-visualisation',
  'remote-desktop',
  's3sync',
  'metrics'
  "
  exit 1
fi

account_id=$(aws sts get-caller-identity --query Account --output text)

echo "Logging into ECR"
aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin $account_id.dkr.ecr.eu-west-2.amazonaws.com

echo "Building docker image"
if [ "$(uname)" == "Darwin" ]; then
  DOCKER_DEFAULT_PLATFORM=linux/amd64 docker build -t $tool:latest -f Dockerfile --target $tool .
else
  docker build -t $tool:latest -f Dockerfile --target $tool .
fi

echo "Pushing docker image to ECR for $environment for $tool and $branch"
docker tag $tool:latest $account_id.dkr.ecr.eu-west-2.amazonaws.com/$environment-$image:$tag
docker push $account_id.dkr.ecr.eu-west-2.amazonaws.com/$environment-$image:$tag

echo "Done. Docker image is now pushed for $tool in $environment. All new tools provisioned will use this image."