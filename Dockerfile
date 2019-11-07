FROM alpine:3.8

ENV TERRAFORM_VERSION=0.12.12
# Configure Go
ENV GOROOT /usr/lib/go
ENV GOPATH /go
ENV PATH /go/bin:$PATH

ARG MODULE_VERSION=0.1.0
ARG INSPEC_VERSION=4.17.14
ARG GEM_SOURCE=https://rubygems.org
ARG TFLINT_VERSION=v0.9.1
ARG YO_VERSION=3.1.0

# Terraform and useful tools
RUN echo http://mirror.math.princeton.edu/pub/alpinelinux/v3.8/main >> /etc/apk/repositories && \
    echo http://mirror.math.princeton.edu/pub/alpinelinux/v3.8/community >> /etc/apk/repositories && \
    echo http://nl.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && \
    apk update && \
    apk --no-cache add \
    nodejs \
    nodejs-npm \
    vim \
    musl-dev \
    linux-headers \
    python3-dev \
    build-base \
    libffi-dev \
    libxml2-dev \
    musl-dev \
    go \
    gcc \
    git \
    openssl-dev \
    openssh-client \
    make \
    curl \
    jq \
    bash \
    ca-certificates \
    unzip \
    openssl \ 
    wget && \
    cd /tmp && \
    wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/bin

RUN mkdir -p ${GOPATH}/src ${GOPATH}/bin && \
    go get -u github.com/hashicorp/terraform-config-inspect
    #go get -u github.com/liamg/tfsec && \

    #go get -u github.com/hairyhenderson/gomplate/cmd/gomplate  

# Install gomplate as not working with go get
RUN curl  -Lo /usr/local/bin/gomplate https://github.com/hairyhenderson/gomplate/releases/download/v3.5.0/gomplate_linux-amd64 -sSL  && \
    chmod 755 /usr/local/bin/gomplate

# TFlint
RUN curl -Lo tflint.zip https://github.com/wata727/tflint/releases/download/${TFLINT_VERSION}/tflint_linux_amd64.zip && \
    unzip tflint.zip -d /bin && \
    rm -f tflint.zip

# Yeoman 
RUN npm install -g yo@${YO_VERSION}

# AWS-Vault
RUN curl -L -o /usr/local/bin/aws-vault https://github.com/99designs/aws-vault/releases/download/v4.5.1/aws-vault-linux-amd64 && \
    chmod 755 /usr/local/bin/aws-vault

# Ruby -> Inspec
# diffutils - This is required for diffy to work on alpine
RUN apk --no-cache add \
  ruby-dev \
  ruby-rdoc \
  ruby-bundler=1.16.2-r1 \
  ruby-json=2.5.7-r0 \
  ruby-webrick \
  diffutils=3.6-r1

RUN gem install --no-document --source ${GEM_SOURCE} --version ${INSPEC_VERSION} inspec && \
    gem install --no-document --source ${GEM_SOURCE} --version ${INSPEC_VERSION} inspec-bin && \
    inspec detect --chef-license=accept-silent && \
    gem install hiera-eyaml

# Python3 and tools
RUN apk add --no-cache python3 && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --upgrade pip setuptools && \    
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
    if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3 /usr/bin/python; fi && \
    ln -s /usr/bin/python3 /usr/local/bin/ && \
    pip3 install --upgrade awscli && \
    pip3 install boto3 && \
    pip3 install ansi2html && \
    #pip3 install scoutsuite && \
    pip3 install --no-cache-dir terrascan==${MODULE_VERSION} && \ 
    rm -r /root/.cache && \
    rm /var/cache/apk/* \
    rm -rf /tmp/* && \
    rm -rf /var/cache/apk/* && \
    rm -rf /var/tmp/* \
    apk del build-base \
    apk update

#RUN apk add --no-cache python3 \
#    python3 -m ensurepip && \
#    rm -r /usr/lib/python*/ensurepip && \
#    pip3 install --upgrade pip setuptools && \
#    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
#    if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3 /usr/bin/python; fi && \
#    rm -r /root/.cache    
#    apk add --no-cache python3=${PYTHON_VERSION} 
#    pip3 install --no-cache-dir terrascan==${MODULE_VERSION} && \
#   find / -type d -name __pycache__ -exec rm -r {} + && \
#    rm -r /usr/lib/python*/ensurepip && \
#    rm -r /usr/lib/python*/lib2to3 && \
#    rm -r /usr/lib/python*/turtledemo && \
#    rm /usr/lib/python*/turtle.py && \
#    rm /usr/lib/python*/webbrowser.py && \
#    rm /usr/lib/python*/doctest.py && \
#    rm /usr/lib/python*/pydoc.py


# Settings
RUN rm /var/cache/apk/* \
    rm -rf /tmp/* && \
    rm -rf /var/cache/apk/* && \
    rm -rf /var/tmp/*

ADD motd /etc/motd
ADD profile  /etc/profile

# Reduce `make` verbosity
ENV MAKEFLAGS="--no-print-directory"

VOLUME ["/data"]
WORKDIR /data

CMD ["/bin/bash","-l"]