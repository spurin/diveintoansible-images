FROM spurin/diveintoansible-rc:ansible

# Install docker
RUN apt-get update \
    && apt-get install -y docker docker.io \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set Docker Env for Docker Tests to run as expected
ENV DOCKER_HOST=tcp://docker:2375

# Copy healthcheck script and service
COPY tests/* /tests/

# Install pip requirements
RUN pip3 install nose2 pytest docker parameterized gitpython

# Patch the deprecated function to always fail rather than warn
RUN sed -i '/^    def deprecated/a\ \ \ \ \ \ \ \ removed = True' /usr/local/lib/python3.10/dist-packages/ansible/utils/display.py

# Override CMD
CMD /bin/startup.sh; nose2 -vs /tests
