FROM quay.io/podman/stable:latest

USER root

ADD install-yum.bash /tmp/install-yum.bash
ADD yum.list /tmp/yum.list
RUN set -x && chmod 755 /tmp/install-yum.bash && \
	/tmp/install-yum.bash && \
	rm -f  /tmp/yum.list /tmp/install-yum.bash

ENV SHELL=bash \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    HOME=/home/${NB_USER} \
    PATH=/opt/micromamba/base/bin:$PATH \
    MAMBA_ROOT_PREFIX=/opt/micromamba/base


ADD environment.yml /tmp/environment.yml

RUN  wget -qO- https://micromamba.snakepit.net/api/micromamba/linux-64/latest | tar -xvj bin/micromamba --strip-components=1 && \
    mv micromamba /usr/bin/micromamba && \
    micromamba shell init -s bash -p ~/micromamba

RUN micromamba create -f /tmp/environment.yml && \
    rm -f /tmp/environment.yml 
    

WORKDIR ${HOME}

RUN ln -s /usr/bin/podman /usr/bin/docker # required by cwltool docker pull even if running with --podman


# yq, jq, aws cli
RUN VERSION="v4.12.2"                                                                               && \
    BINARY="yq_linux_amd64"                                                                         && \
    wget --quiet https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY}.tar.gz -O - |\
    tar xz && mv ${BINARY} /usr/bin/yq                                                              && \
    curl -s -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 > /usr/bin/jq     && \
    chmod +x /usr/bin/jq                                                                            && \
    /opt/micromamba/base/bin/pip3 install awscli                                                           && \
    /opt/micromamba/base/bin/pip3 install awscli-plugin-endpoint

# kubectl
RUN curl -s -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"  && \
    chmod +x kubectl                                                                                                    && \
    mv ./kubectl /usr/bin/kubectl

RUN echo "alias ll='ls -l'" >> /home/.bashrc

RUN git clone https://github.com/Terradue/calrissian.git            && \
    cd calrissian                                                   && \
    git checkout feature/sprint1                                    && \
    /opt/micromamba/base/bin/python setup.py install                && \
    rm -fr /home/calrissian

RUN echo "PS1='[\u@\h \W] $ '" >> /home/.bashrc                     && \
    echo "micromamba activate" >> /home/.bashrc

ENV PATH=/opt/micromamba/base/bin:$PATH

