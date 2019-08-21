#!/bin/bash
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

# change name of dir, change username + dir, change env vars
#cd /
#cd /home
#export HOME=/home/${JUPYTERHUB_USER}
#export NB_USER=$JUPYTERHUB_USER
#/startup ${NB_USER} ${JUPYTERHUB_USER}

set -e

if [[ ! -z "${JUPYTERHUB_API_TOKEN}" ]]; then
  # launched by JupyterHub, use single-user entrypoint
  exec /usr/local/bin/start-singleuser.sh "$@"
elif [[ ! -z "${JUPYTER_ENABLE_LAB}" ]]; then
  . /usr/local/bin/start.sh jupyter lab "$@"
else
  . /usr/local/bin/start.sh jupyter notebook "$@"
fi
