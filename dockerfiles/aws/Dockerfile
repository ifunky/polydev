FROM amazonlinux:2 

RUN yum update -y \
  && yum install -y tar gcc-c++ git gzip make wget which groff less glibc python3 unzip


# AWS CLI V2, Copilot, CDK 
RUN cd /tmp && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    curl -Lo /usr/local/bin/copilot https://github.com/aws/copilot-cli/releases/download/v0.2.0/copilot-linux-v0.2.0  && \
    chmod +x /usr/local/bin/copilot && \
    curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm" -o "session-manager-plugin.rpm" && \
    yum install -y session-manager-plugin.rpm && \
    curl -sL https://rpm.nodesource.com/setup_12.x | bash - && \
    yum install -y nodejs && \
    npm install -g aws-cdk

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