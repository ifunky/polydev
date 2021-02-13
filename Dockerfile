FROM alpine:3.12.1

ENV TERRAFORM_VERSION=0.13.5
# Configure Go
ENV GOROOT /usr/lib/go
ENV GOPATH /go
ENV PATH /go/bin:$PATH

ARG MODULE_VERSION=0.1.0
ARG INSPEC_VERSION=4.17.14
ARG GEM_SOURCE=https://rubygems.org
ARG TFLINT_VERSION=v0.15.1
ARG YO_VERSION=3.1.1
ARG PACKER_VERSION=1.5.1
ARG HELM_VERSION=2.16.3
ENV KUBE_VERSION=v1.17.3
ARG AWS_IAM_AUTH_VERSION=0.5.0

# Terraform and useful tools
RUN echo http://mirror.math.princeton.edu/pub/alpinelinux/v3.8/main >> /etc/apk/repositories && \
    echo http://mirror.math.princeton.edu/pub/alpinelinux/v3.8/community >> /etc/apk/repositories && \
    echo http://nl.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && \
    apk update && \
    apk --no-cache add  \
    vim \
    musl-dev \
    nodejs-current \
    npm \
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

RUN go get -u github.com/kiranjthomas/terraform-config-inspect && \
    go get -u github.com/tfsec/tfsec/cmd/tfsec
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

# Packer Install
RUN curl -Lo packer.zip https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip && \
    unzip packer.zip -d /usr/local/bin && \
    rm -f packer.zip

# Helm & kubectl
RUN curl -L https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz |tar xvz && \
    mv linux-amd64/helm /usr/bin/helm && \
    chmod +x /usr/bin/helm && \
    wget -q https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

RUN curl -LO https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v${AWS_IAM_AUTH_VERSION}/aws-iam-authenticator_${AWS_IAM_AUTH_VERSION}_linux_amd64 && \
    mv aws-iam-authenticator_${AWS_IAM_AUTH_VERSION}_linux_amd64 /usr/bin/aws-iam-authenticator && \
    chmod +x /usr/bin/aws-iam-authenticator

RUN curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp && \
    mv /tmp/eksctl /usr/bin && \
    chmod +x /usr/bin/eksctl

# Ruby -> Inspec
RUN apk --no-cache add \
  ruby-dev \
  ruby-rdoc \
  ruby-bundler \
  ruby-json \
  ruby-webrick \
  diffutils=3.6-r1

RUN gem install bigdecimal && \
    gem install --no-document --source ${GEM_SOURCE} --version ${INSPEC_VERSION} inspec && \
    gem install --no-document --source ${GEM_SOURCE} --version ${INSPEC_VERSION} inspec-bin && \
    inspec detect --chef-license=accept-silent && \
    gem install hiera-eyaml bundler

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
    pip3 install yamllint && \
    pip3 install checkov && \
    #pip3 install scoutsuite && \
    pip3 install --no-cache-dir terrascan==${MODULE_VERSION} && \ 
    rm -r /root/.cache && \
    rm /var/cache/apk/* \
    rm -rf /tmp/* && \
    rm -rf /var/cache/apk/* && \
    rm -rf /var/tmp/* \
    apk del build-base \
    apk update

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
