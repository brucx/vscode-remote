FROM ubuntu:22.04

ARG EXTRA_PKGS

RUN apt-get update && apt-get install --no-install-recommends -y \
    ca-certificates curl sudo openssh-server bash git \
    iproute2 apt-transport-https gnupg-agent software-properties-common \
    # Install extra packages you need for your dev environment
    ${EXTRA_PKGS} && \
    apt autoremove -y

ARG USER
RUN test -n "$USER"

# Create your user
RUN adduser --disabled-password --gecos '' --home /data/home ${USER}
# passwordless sudo for your user's group
RUN echo "%${USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

ENV USER_ARG=${USER}

RUN apt-get install --no-install-recommends -y iptables libdevmapper1.02.1 apt-transport-https ca-certificates curl software-properties-common \
    && apt install apt-transport-https ca-certificates curl software-properties-common \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y containerd.io docker-ce docker-ce-cli \
    && usermod -aG docker ${USER}

# Setup your SSH server daemon, copy pre-generated keys
RUN rm -rf /etc/ssh/ssh_host_*_key*
COPY etc/ssh/sshd_config /etc/ssh/sshd_config

COPY ./entrypoint ./entrypoint
COPY ./docker-entrypoint.d/* ./docker-entrypoint.d/

ENTRYPOINT ["./entrypoint"]

CMD ["/usr/sbin/sshd", "-D"]
