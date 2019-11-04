# docker build . -t raphaelguzman/datajoint-jnb:v3.0
# docker build -f alpine.dockerfile -t raphaelguzman/datajoint-jnb:v0.2.6 .
# curl https://cloud.docker.com/v2/repositories/raphaelguzman/datajoint-jnb/tags/?page_size=25 | jq '[.results[] | { tag: .name, size: .images[0].size }]|.[].size/=1024*1024'
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

# Ubuntu 18.04 (bionic) from 2018-05-26
# https://github.com/docker-library/official-images/commit/aac6a45b9eb2bffb8102353c350d341a410fb169
# ARG BASE_CONTAINER=ubuntu:bionic-20180526@sha256:c8c275751219dadad8fa56b3ac41ca6cb22219ff117ca98fe82b42f24e1ba64e
# ARG BASE_CONTAINER=debian:9.9-slim
ARG BASE_CONTAINER=alpine:3.10

# #Temp Image to create exec to allow UID/GID to be updated on boot
# FROM golang:alpine3.9 as go_tmp
# COPY ./startup.go /startup.go
# RUN cd / && go build startup.go

FROM $BASE_CONTAINER as base
# COPY --from=go_tmp /startup /startup
LABEL maintainer="Jupyter Project <jupyter@googlegroups.com>"
ARG NB_USER="jovyan"
ARG NB_USER_HOME=".jovyan"
ARG NB_UID="1000"
ARG NB_GID="100"

USER root

# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)
ENV DEBIAN_FRONTEND noninteractive
# RUN apt-get update && apt-get -yq dist-upgrade \
#  && apt-get install -yq --no-install-recommends \
#     wget \
#     bzip2 \
#     ca-certificates \
#     sudo \
#     locales \
#     fonts-liberation \
#  && rm -rf /var/lib/apt/lists/*
 RUN apk update && apk upgrade\
 && apk --no-cache add \
    wget \
    bzip2 \
    ca-certificates \
    sudo \
   #  locales \
    ttf-liberation \
    #usermod groupmod
    shadow

# RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
#     locale-gen

# Install locales fix
RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.25-r0/glibc-2.25-r0.apk && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.25-r0/glibc-bin-2.25-r0.apk && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.25-r0/glibc-i18n-2.25-r0.apk && \
    apk add glibc-bin-2.25-r0.apk glibc-i18n-2.25-r0.apk glibc-2.25-r0.apk

# Iterate through all locale and install it
# Note that locale -a is not available in alpine linux, use `/usr/glibc-compat/bin/locale -a` instead
COPY ./locale.md /locale.md
RUN cat /locale.md | xargs -i /usr/glibc-compat/bin/localedef -i {} -f UTF-8 {}.UTF-8

# Set the lang, you can also specify it as as environment variable through docker-compose.yml
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8

# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/sh \
    NB_USER=$NB_USER \
    NB_UID=$NB_UID \
    NB_GID=$NB_GID \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV PATH=$CONDA_DIR/bin:$PATH \
    HOME=/home/$NB_USER_HOME

# Add a script that we will use to correct permissions after running certain commands
ADD fix-permissions-alpine /usr/local/bin/fix-permissions

# Enable prompt color in the skeleton .bashrc before creating the default NB_USER
#no fix yet
# RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc

# Create NB_USER wtih name jovyan user with UID=1000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
ENV PATH "/usr/local/bin:$PATH"
RUN apk add linux-pam
RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    chmod g+w /etc/passwd && \
    mkdir -p /home/$NB_USER_HOME && \
    # addgroup --gid $NB_GID $NB_USER && \
    # adduser --disabled-password -h /home/$NB_USER_HOME -s /bin/sh -u $NB_UID $NB_USER && \
    # echo "$NB_USER:datajoint" | chpasswd && \
    echo "${NB_USER}:x:${NB_UID}:${NB_GID}:Developer,,,:/home/${NB_USER_HOME}:/bin/sh" >> /etc/passwd && \
    chown ${NB_UID}:${NB_GID} -R /home/${NB_USER_HOME} && \
    mkdir -p $CONDA_DIR && \
    # chown $NB_USER:$NB_GID $CONDA_DIR && \
    chown 0:$NB_GID $CONDA_DIR && \
    # fix-permissions $HOME && \
    # fix-permissions "$(dirname $CONDA_DIR)" && \
    # chmod 4755 /startup && \
    apk add bash
# RUN ls -la $(dirname $CONDA_DIR)
USER $NB_USER

# Setup work directory for backward-compatibility
RUN mkdir /home/$NB_USER_HOME/work && \
    fix-permissions /home/$NB_USER_HOME

USER root
# Install conda as jovyan and check the md5 sum provided on the download site
ENV MINICONDA_VERSION=4.5.12 \
    CONDA_VERSION=4.6.14

RUN cd /tmp && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    echo "866ae9dff53ad0874e1d1a60b1ad1ef8 *Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh" | md5sum -c - && \
    bash Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    echo "conda ${CONDA_VERSION}" >> $CONDA_DIR/conda-meta/pinned && \
    $CONDA_DIR/bin/conda config --system --prepend channels conda-forge && \
    $CONDA_DIR/bin/conda config --system --set auto_update_conda false && \
    $CONDA_DIR/bin/conda config --system --set show_channel_urls true && \
    $CONDA_DIR/bin/conda install --quiet --yes conda && \
    $CONDA_DIR/bin/conda update --all --quiet --yes && \
    conda list python | grep '^python ' | tr -s ' ' | cut -d '.' -f 1,2 | sed 's/$/.*/' >> $CONDA_DIR/conda-meta/pinned && \
    conda clean --all -f -y && \
    rm -rf /home/$NB_USER_HOME/.cache/yarn && \
    # fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER_HOME
# USER $NB_USER

# Install Tini
RUN conda install --quiet --yes 'tini=0.18.0' && \
    conda list tini | grep tini | tr -s ' ' | cut -d ' ' -f 1,2 >> $CONDA_DIR/conda-meta/pinned && \
    conda clean --all -f -y && \
    # fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER_HOME

# Install Jupyter Notebook, Lab, and Hub
# Generate a notebook server config
# Cleanup temporary files
# Correct permissions
# Do all this in a single RUN command to avoid duplicating all of the
# files across image layers when the permissions change
RUN conda install --quiet --yes \
    'notebook=5.7.8' \
    'jupyterhub=1.0.0' \
    'jupyterlab=0.35.5' && \
    conda clean --all -f -y && \
    jupyter labextension install @jupyterlab/hub-extension@^0.12.0 && \
    npm cache clean --force && \
    jupyter notebook --generate-config && \
    rm -rf $CONDA_DIR/share/jupyter/lab/staging && \
    rm -rf /home/$NB_USER_HOME/.cache/yarn && \
    # fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER_HOME

# USER root

EXPOSE 8888
WORKDIR $HOME

# Configure container startup
ENTRYPOINT ["tini", "-g", "--"]
CMD ["start-notebook.sh"]

# Add local files as late as possible to avoid cache busting
COPY start.sh /usr/local/bin/
COPY start-notebook.sh /usr/local/bin/
COPY start-singleuser.sh /usr/local/bin/
COPY jupyter_notebook_config.py /etc/jupyter/
RUN fix-permissions /etc/jupyter/

# Switch back to jovyan to avoid accidental container runs as root
USER $NB_USER

USER root

# Install all OS dependencies for fully functional notebook server
# RUN apt-get update && apt-get install -yq --no-install-recommends \
#     build-essential \
#     emacs \
#     git \
#     inkscape \
#     jed \
#     libsm6 \
#     libxext-dev \
#     libxrender1 \
#     lmodern \
#     netcat \
#     pandoc \
#     python-dev \
#     texlive-fonts-extra \
#     texlive-fonts-recommended \
#     texlive-generic-recommended \
#     texlive-latex-base \
#     texlive-latex-extra \
#     texlive-xetex \
#     tzdata \
#     unzip \
#     nano \
#     #DJ specific
#     graphviz \
#     && rm -rf /var/lib/apt/lists/*

RUN apk update && apk --no-cache add \
#     build-base \
#     emacs \
#     git \
#     inkscape \
#    #  jed \
#    #  libsm6 \
#     libxext-dev \
#    #  libxrender1 \
#    #  lmodern \
#     netcat-openbsd \
#    #  pandoc \
#     python-dev \
#    #  texlive-full \
#     tzdata \
#     unzip \
#     nano \
    #DJ specific
    graphviz ghostscript-fonts \
    # DJ extras
    git mysql-client \
    && rm -rf /var/lib/apt/lists/* 
    # && \
    # usermod -a -G shadow root

# Switch back to jovyan to avoid accidental container runs as root
USER $NB_USER
#DJ specific
RUN pip install --user pandas numpy networkx backcall
RUN pip install --user matplotlib
RUN pip install --user cryptography
RUN pip install --user datajoint --pre
COPY post-start.sh /usr/local/bin/

USER root
RUN \ 
    # chown -R $NB_UID:$NB_GID /home/$NB_USER_HOME && \
    mkdir /home/shared && \
    chown -R $NB_UID:$NB_GID /home/shared && \
    chmod +x /usr/local/bin/post-start.sh
    # git clone https://github.com/ttngu207/Li-2015a.git /home/shared
USER $NB_USER

FROM scratch
COPY --from=base / /
LABEL maintainerName="Raphael Guzman" \
      maintainerEmail="raphael@vathes.com" \
      maintainerCompany="DataJoint"

ARG NB_USER="jovyan"
ARG NB_USER_HOME=".jovyan"
ARG NB_UID="1000"
ARG NB_GID="100"
ENV DEBIAN_FRONTEND noninteractive
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/sh \
    NB_USER=$NB_USER \
    NB_USER_HOME=$NB_USER_HOME \
    NB_UID=$NB_UID \
    NB_GID=$NB_GID \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV PATH=$CONDA_DIR/bin:$PATH \
    HOME=/home/$NB_USER_HOME
USER $NB_USER
ENV MINICONDA_VERSION=4.5.12 \
    CONDA_VERSION=4.6.14
USER root

EXPOSE 8888
WORKDIR $HOME
ENTRYPOINT ["tini", "-g", "--"]
CMD ["start-notebook.sh"]
# RUN fix-permissions /etc/jupyter/
USER $NB_USER
# USER root