FROM spurin/container-systemd-sshd-ttyd:ubuntu_22.04

# Install editors and common utilities, openssl (for the healthcheck script), python and associated build utilities
RUN apt-get update \
    && apt-get install -y vim nano \
    openssl \
    build-essential python3 python3-pip python3-dev libffi-dev libssl-dev \
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

# Install ansible, using pip
RUN pip3 install ansible==10.3.0 passlib

# Patch Ansible, so that the SSH control_path is using /dev/shm by default, rather than ~/.ansible/cp
# When running a container, this issue relates to a problem with overlayfs.  Without this patch, updates to ansible.cfg are required.
#
# The following thread has more details https://github.com/ansible-semaphore/semaphore/issues/309
RUN perl -p -i -e 's/default: ~\/.ansible\/cp/default: \/dev\/shm/g' $(python3 -c 'import ansible;print(ansible.__file__)' | sed 's/__init__.py/config\/base.yml/g')
RUN perl -p -i -e 's/default: ~\/.ansible\/cp/default: \/dev\/shm/g' $(python3 -c 'import ansible;print(ansible.__file__)' | sed 's/__init__.py/plugins\/connection\/ssh.py/g')

# Temporary patch for https://github.com/ansible/ansible/issues/75167
RUN perl -p -i -e "s/if not self.get_option\('host_key_checking'\):/if self.get_option\('host_key_checking'\) is False:/g" $(python3 -c 'import ansible;print(ansible.__file__)' | sed 's/__init__.py/plugins\/connection\/ssh.py/g')

# Set intepreter to auto_silent (Ansible 10) as per https://docs.ansible.com/ansible-core/2.17/reference_appendices/interpreter_discovery.html
RUN sed -i '/INTERPRETER_PYTHON:/,/default:/ s/default:.*/default: auto_silent/' /usr/local/lib/python3.10/dist-packages/ansible/config/base.yml

# Setup login banner for guidance
COPY login_banner /etc
RUN sed -i '1i auth optional pam_echo.so file=/etc/login_banner' /etc/pam.d/login

# Fix for SSH for video consistency (SSH Hostkey entries)
RUN sed -i \
    -e '/^#\s*CheckHostIP\s*no\s*$/c\CheckHostIP yes' \
    -e '/^#\s*CheckHostIP\s*yes\s*$/c\CheckHostIP yes' \
    -e '/^CheckHostIP\s*no\s*$/c\CheckHostIP yes' \
    -e '/^CheckHostIP\s*yes\s*$/c\CheckHostIP yes' /etc/ssh/ssh_config && \
    if ! grep -q "^CheckHostIP\s*yes$" /etc/ssh/ssh_config; then \
        echo 'CheckHostIP yes' >> /etc/ssh/ssh_config; \
    fi && \
    if ! grep -q "^HostKeyAlgorithms" /etc/ssh/ssh_config; then \
        echo 'HostKeyAlgorithms=ecdsa-sha2-nistp256' >> /etc/ssh/ssh_config; \
    else \
        sed -i 's/^\s*#\?\s*HostKeyAlgorithms.*/HostKeyAlgorithms=ecdsa-sha2-nistp256/' /etc/ssh/ssh_config; \
    fi

# Add world writeable /shared area
RUN mkdir /shared && chmod 777 /shared

# Add ssh keys util
COPY setup_ssh_keys.sh /utils

# Copy test suite
COPY run_test_suite.sh /utils
