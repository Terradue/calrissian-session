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

RUN \
    chown -R mambauser:1000 /opt/conda/

RUN \
    echo "**** install Stars ****" && \
    stars_version=2.10.17 && \
    curl -L https://github.com/Terradue/Stars/releases/download/${stars_version}/Stars.${stars_version}.linux-x64.deb > Stars.deb && \
    echo "deb http://security.ubuntu.com/ubuntu focal-security main" | tee /etc/apt/sources.list.d/focal-security.list && \
    apt-get update && \
    apt-get install libssl1.1 && \
    dpkg -i Stars.deb && \
    rm Stars.deb

USER mambauser

RUN micromamba install -c conda-forge -n base python=3.7 pip

WORKDIR /home/mambauser
RUN \
    echo "**** install calrissian ****" && \
    /opt/conda/bin/pip install calrissian

ENTRYPOINT []