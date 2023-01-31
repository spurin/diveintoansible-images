FROM spurin/container-systemd-sshd-ttyd:centos_8

# Install editors and common utilities, openssl (needed for healthcheck script)
## python3 added to satisfy python dependency for remote module execution
RUN yum install -y vim nano \
    openssl \
    diffutils iputils git net-tools lsof unzip \
    python3 \
    && yum clean all

# Copy healthcheck script and service
COPY healthcheck.sh /utils/healthcheck.sh
COPY healthcheck.service /lib/systemd/system/healthcheck.service

# Enable healthcheck service
RUN ln -s /lib/systemd/system/healthcheck.service /etc/systemd/system/multi-user.target.wants/healthcheck.service

# Configure sshd to run on port 2222
RUN sed -ri 's/^#Port 22/Port 2222/' /etc/ssh/sshd_config

# Open Ports
EXPOSE 2222
