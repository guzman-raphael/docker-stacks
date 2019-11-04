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

# remove files and hidden files
rm -R /home/shared/*
rm -rf /home/shared/.* 2> /dev/null
# #dj config (would have been better if this was in user HOME...)
# if [ ! -f "/usr/local/bin/.datajoint_config.json" ]; then
#     cp /tmp/.datajoint_config.json /usr/local/bin/.datajoint_config.json
# fi
#clone
git clone $NB_REPO /home/shared
#copy global config
cp /usr/local/bin/.datajoint_config.json ./
#pip install requirements in root + pipeline
pip install --user -r /home/shared/requirements.txt
pip install --user /home/shared
#copy subset
mkdir /tmp/shared
cp -R /home/shared/${NB_REPO_RELPATH}/* /tmp/shared
cp -r /home/shared/${NB_REPO_RELPATH}/.[^.]* /tmp/shared
#remove files and hidden files
rm -R /home/shared/*
rm -rf /home/shared/.* 2> /dev/null
#move contents
mv /tmp/shared/* /home/shared
mv /tmp/shared/.[^.]* /home/shared
#remove prev temp directory
rm -R /tmp/shared

cd /home/${NB_USER}

"$@"