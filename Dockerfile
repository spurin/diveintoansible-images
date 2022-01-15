FROM spurin/container-systemd-sshd-ttyd:centos_stream9

# Install editors and common utilities, openssl (needed for healthcheck script)
RUN yum install -y vim nano \
    openssl \
    diffutils iputils git net-tools lsof unzip \
    && yum clean all

# Copy healthcheck script and service
COPY healthcheck.sh /utils/healthcheck.sh
COPY healthcheck.service /lib/systemd/system/healthcheck.service

# Enable healthcheck service
RUN ln -s /lib/systemd/system/healthcheck.service /etc/systemd/system/multi-user.target.wants/healthcheck.service
