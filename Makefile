.SHELL := /usr/bin/bash

export WIZ_ENV = test

define csat
	@docker run -it --rm \
		--env AWS_DEFAULT_REGION="$(AWS_REGION)" \
		--user "$$(id -u):$$(id -g)" \
		-v "$$PWD:/data" \
		wiz-sec/csatools:latest $1
endef

help:
	@grep -E '^[a-zA-Z_-_\/]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build: ## Build the container
	@docker build -t wiz-sec/csatools:latest .

build/aws: ## Build AWS CLI and other related tools
	@docker build -t wiz-sec/csatools-aws:latest -f dockerfiles/aws/Dockerfile dockerfiles/aws/

build/aws/nocache: ## Build AWS CLI and other related tools (from scratch)
	@docker build --no-cache -t wiz-sec/polydev-aws:latest -f dockerfiles/aws/Dockerfile dockerfiles/aws/

build/nocache: ## Rebuild with no cache to force fresh rebuild
	@docker build --no-cache -t wiz-sec/csatools:latest .

publish: ## Publish to Dockerhub
	@docker push wiz-sec/csatools:latest

auth: ## WizCli authentication
	@wizcli auth --id 8UMOsfxbhThEsgprnZRf3gV9h46fPGzT --secret 4pDtT67M3sFU4Yx3T_GgjujwX1Ia4go4uhCubn_T8wnJiWYQnFkWRiyifLEfAbZA

scan: auth ##  Local docker security scan
	#@trivy image --format template --template "@contrib/junit.tpl" -o junit-report.xml wiz-sec/polydev:latest
	#@trivy --exit-code 1 --no-progress wiz-sec/csatools:latest
	@wizcli docker scan --image wiz-sec/csatools:latest

csatools: ## Run the shell :-)
	@docker run -it --rm \
	-e AWS_ACCESS_KEY_ID \
	-e AWS_SECRET_ACCESS_KEY \
	-e AWS_SESSION_TOKEN \
	-e AWS_SECURITY_TOKEN \
	-v ~/.ssh:/root/.ssh \
	-v ~/.aws:/root/.aws \
	-v "$$PWD:/data" \
	-v /var/run/docker.sock:/var/run/docker.sock \
	wiz-sec/csatools:latest

csatools/aws: ## Run the AWS shell :-)
	@ docker run -rm -it \
	-e AWS_ACCESS_KEY_ID \
	-e AWS_SECRET_ACCESS_KEY \
	-e AWS_SESSION_TOKEN \
	-e AWS_SECURITY_TOKEN \
	-v ~/.ssh:/root/.ssh \
	-v ~/.aws:/root/.aws \	
	-v "$$PWD:/data" \	
	wiz-sec/csatools-aws:latest

csatools/scan: ## scan container images
	$(call csat,make scan)