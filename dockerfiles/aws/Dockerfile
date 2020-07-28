FROM amazonlinux:2 

RUN yum update -y \
  && yum install -y tar git gzip make wget which groff less glibc unzip gcc openssl-devel bzip2-devel libffi-devel

RUN cd /opt && \
    wget https://www.python.org/ftp/python/3.7.7/Python-3.7.7.tgz && \
    tar xzf Python-3.7.7.tgz && \
    cd Python-3.7.7 && \
    ./configure --enable-optimizations --with-ensurepip=install && \
    make altinstall

# AWS CLI V2, Copilot
RUN cd /tmp && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    curl -Lo /usr/local/bin/copilot https://github.com/aws/copilot-cli/releases/download/v0.2.0/copilot-linux-v0.2.0  && \
    chmod +x /usr/local/bin/copilot && \
    curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm" -o "session-manager-plugin.rpm" && \
    yum install -y session-manager-plugin.rpm

# Clean up
RUN rm -rf /tmp/*

# Reduce `make` verbosity
ENV MAKEFLAGS="--no-print-directory"

ADD motd /etc/motd
ADD profile  /etc/profile.d/profile.sh

RUN chmod +x /etc/profile.d/profile.sh

VOLUME ["/data"]
WORKDIR /data

CMD ["/bin/bash","-l"]
