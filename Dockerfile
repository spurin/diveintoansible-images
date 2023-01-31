FROM spurin/container-systemd-sshd-ttyd:ubuntu_22.04

# Install editors and common utilities, openssl (for the healthcheck script)
RUN apt-get update \
    && apt-get install -y vim nano \
    openssl \
    iproute2 iputils-ping git net-tools lsof unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy healthcheck script and service
COPY healthcheck.sh /utils/healthcheck.sh
COPY healthcheck.service /lib/systemd/system/healthcheck.service

# Enable healthcheck service
RUN ln -s /lib/systemd/system/healthcheck.service /etc/systemd/system/multi-user.target.wants/healthcheck.service

# Friendly .vimrc starter
COPY .vimrc /etc/skel
