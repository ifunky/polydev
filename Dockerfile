ARG ALPINE_VERSION=3.16.2

FROM alpine:3.16.2

ENV TERRAFORM_VERSION=1.3.1
ENV KUBE_VERSION=v1.25.0
ENV WIZCLI_IN_CONTAINER=1
ENV WIZ_DIR=/root/.wiz
ENV AWS_PAGER=
ENV ASSUME_NO_MOVING_GC_UNSAFE_RISK_IT_WITH=go1.18

# Configure Go
ENV GOROOT /usr/lib/go
ENV GOPATH /go
ENV PATH /go/bin:$PATH

ARG AWS_CLI_VERSION=2.7.28
ARG INSPEC_VERSION=5.18.14
ARG GEM_SOURCE=https://rubygems.org
ARG TFLINT_VERSION=v0.39.3
ARG YO_VERSION=4.3.0
ARG PACKER_VERSION=1.8.3
ARG HELM_VERSION=2.16.3
ARG AWS_IAM_AUTH_VERSION=0.5.0
ARG CONFTEST_VERSION=0.34.0

# Terraform and useful tools
RUN echo http://mirror.math.princeton.edu/pub/alpinelinux/v3.8/main >> /etc/apk/repositories && \
    echo http://mirror.math.princeton.edu/pub/alpinelinux/v3.8/community >> /etc/apk/repositories && \
    echo http://nl.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && \
    apk update && \
    apk --no-cache add  \
    docker-cli \
    vim \
    musl-dev \
    nodejs-current \
    linux-headers \
    python3-dev \
    py3-pip \
    build-base \
    libffi-dev \
    libxml2-dev \
    musl-dev \
    go \
    gcc \
    git \
    groff \
    cmake \
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
    # Python setup
    ln -sf python3 /usr/bin/python && \
    python3 -m ensurepip && \
    pip3 install --no-cache --upgrade pip setuptools && \
    cd /tmp && \
    wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/bin

# Install npm as Alpine apk installs an old version
RUN curl -L https://www.npmjs.com/install.sh | sh 

# AWS CLI V2
RUN git clone --single-branch --depth 1 -b ${AWS_CLI_VERSION} https://github.com/aws/aws-cli.git

WORKDIR aws-cli
RUN sed -i'' 's/PyInstaller.*/PyInstaller==5.2/g' requirements-build.txt
RUN python -m venv venv
RUN . venv/bin/activate
RUN scripts/installers/make-exe
RUN unzip -q dist/awscli-exe.zip
RUN aws/install --bin-dir /aws-cli-bin
RUN /aws-cli-bin/aws --version

# reduce image size: remove autocomplete and examples
RUN rm -rf /usr/local/aws-cli/v2/current/dist/aws_completer /usr/local/aws-cli/v2/current/dist/awscli/data/ac.index /usr/local/aws-cli/v2/current/dist/awscli/examples && \
    find /usr/local/aws-cli/v2/current/dist/awscli/botocore/data -name examples-1.json -delete

RUN go install github.com/hairyhenderson/gomplate/v3/cmd/gomplate@v3.10.0 && \
    go install github.com/hashicorp/terraform-config-inspect@latest 

# TFlint
RUN curl -Lo tflint.zip https://github.com/wata727/tflint/releases/download/${TFLINT_VERSION}/tflint_linux_amd64.zip && \
    unzip tflint.zip -d /bin && \
    rm -f tflint.zip

# Conftest
RUN wget https://github.com/open-policy-agent/conftest/releases/download/v${CONFTEST_VERSION}/conftest_${CONFTEST_VERSION}_Linux_x86_64.tar.gz  && \
    tar xzf conftest_${CONFTEST_VERSION}_Linux_x86_64.tar.gz && \
    mv conftest /usr/local/bin

# Yeoman 
RUN npm install -g yo@${YO_VERSION}

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

#RUN curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp && \
#    mv /tmp/eksctl /usr/bin && \
#    chmod +x /usr/bin/eksctl

# Ruby -> Inspec
RUN apk --no-cache add \
  ruby-dev \
  ruby-rdoc \
  ruby-bundler \
  ruby-json \
  ruby-webrick \
  diffutils

RUN gem install bigdecimal && \
   gem install --no-document --source ${GEM_SOURCE} --version ${INSPEC_VERSION} inspec && \
   gem install --no-document --source ${GEM_SOURCE} --version ${INSPEC_VERSION} inspec-bin && \
   gem install --no-document --source ${GEM_SOURCE} --version ${INSPEC_VERSION} inspec-bin

# Wiz CLI
RUN curl -o /usr/local/bin/wizcli https://wizcli.app.wiz.io/wizcli && \
    chmod +x /usr/local/bin/wizcli

# Python and apk idy up
RUN apk add --no-cache  && \
    #python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    #pip3 install --upgrade pip setuptools && \    
    #if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
    #if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3 /usr/bin/python; fi && \
    #ln -s /usr/bin/python3 /usr/local/bin/ && \
    pip3 install boto3 && \
    pip3 install yamllint && \
    pip3 install wheel && \
    pip3 install checkov && \
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
