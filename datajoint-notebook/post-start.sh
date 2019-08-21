#!/bin/bash

#Fix UID/GID
# /startup ${NB_USER} ${JUPYTERHUB_USER}

# # change name of dir, change username + dir, change env vars
# #permissions
# # sed -i "s|${NB_USER}|${JUPYTERHUB_USER}|g" /etc/passwd
# #permissions
# mv /home/${NB_USER} /home/${JUPYTERHUB_USER}
# export OLDPWD=/home/${JUPYTERHUB_USER}
# export HOME=/home/${JUPYTERHUB_USER}
# export NB_USER=$JUPYTERHUB_USER

rm -R /home/shared/*
git clone $NB_REPO /home/shared
cp /usr/local/bin/.datajoint_config.json ./

pip install --user /home/shared