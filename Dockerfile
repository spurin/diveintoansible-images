FROM spurin/container-systemd-sshd-ttyd:ubuntu_20.04

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
RUN pip3 install ansible==5.5.0

# Patch Ansible, so that the SSH control_path is using /dev/shm by default, rather than ~/.ansible/cp
# When running a container, this issue relates to a problem with overlayfs.  Without this patch, updates to ansible.cfg are required.
#
# The following thread has more details https://github.com/ansible-semaphore/semaphore/issues/309
RUN perl -p -i -e 's/default: ~\/.ansible\/cp/default: \/dev\/shm/g' $(python3 -c 'import ansible;print(ansible.__file__)' | sed 's/__init__.py/config\/base.yml/g')
RUN perl -p -i -e 's/default: ~\/.ansible\/cp/default: \/dev\/shm/g' $(python3 -c 'import ansible;print(ansible.__file__)' | sed 's/__init__.py/plugins\/connection\/ssh.py/g')

# Temporary patch for https://github.com/ansible/ansible/issues/75167
RUN perl -p -i -e "s/if not self.get_option\('host_key_checking'\):/if self.get_option\('host_key_checking'\) is False:/g" $(python3 -c 'import ansible;print(ansible.__file__)' | sed 's/__init__.py/plugins\/connection\/ssh.py/g')
