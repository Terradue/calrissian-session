FROM mambaorg/micromamba:1.4-jammy

USER root

ENV USERNAME=mambauser

ENV PATH=/opt/conda/bin/:$PATH

RUN \
    apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl sudo git nodejs wget curl git-flow vim psutils procps podman zip unzip uidmap slirp4netns

RUN \
    echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

RUN usermod -u 1001 -g 100 mambauser

RUN \
    chown -R mambauser:100 /opt/conda/

RUN \
    echo "**** install Stars ****" && \
    stars_version=2.10.17 && \
    curl -L https://github.com/Terradue/Stars/releases/download/${stars_version}/Stars.${stars_version}.linux-x64.deb > Stars.deb && \
    echo "deb http://security.ubuntu.com/ubuntu focal-security main" | tee /etc/apt/sources.list.d/focal-security.list && \
    apt-get update && \
    apt-get install libssl1.1 && \
    dpkg -i Stars.deb && \
    rm Stars.deb

RUN \
    echo "**** install yq, aws cli ****" && \
    VERSION="v4.12.2"                                                                               && \
    BINARY="yq_linux_amd64"                                                                         && \
    wget --quiet https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY}.tar.gz -O - |\
    tar xz && mv ${BINARY} /usr/bin/yq 

RUN \
    ln -s /usr/bin/podman /usr/bin/docker

RUN \
    mkdir /workspace && \
    chown -R mambauser:100 /workspace

USER mambauser

RUN micromamba install -c conda-forge -n base python=3.7 pip nose2

RUN \
    /opt/conda/bin/pip3 install awscli                                                            && \
    /opt/conda/bin/pip3 install awscli-plugin-endpoint                                              

WORKDIR /home/mambauser
RUN \
    echo "**** install calrissian ****" && \
    /opt/conda/bin/pip3 install calrissian


ENTRYPOINT []