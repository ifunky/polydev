.SHELL := /usr/bin/bash

help:
	@grep -E '^[a-zA-Z_-_\/]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build: ## Build PolyDev
	@docker build -t ifunky/polydev:latest .

build/amplify: ## Build PolyDev
	@docker build -t ifunky/polydev-amplify:latest -f amplify-hugo.dockerfile .


build/aws: ## Build AWS CLI and other related tools
	@docker build -t ifunky/polydev-aws:latest -f dockerfiles/aws/Dockerfile dockerfiles/aws/

build/aws/nocache: ## Build AWS CLI and other related tools (from scratch)
	@docker build --no-cache -t ifunky/polydev-aws:latest -f dockerfiles/aws/Dockerfile dockerfiles/aws/

build/nocache: ## Rebuild with no cache to force fresh rebuild
	@docker build --no-cache -t ifunky/polydev:latest .

publish: ## Publish to Dockerhub
	@docker push ifunky/polydev:latest
	@docker push ifunky/polydev-amplify:latest

scan: ##  Local docker security scan 
	@trivy --exit-code 0 --no-progress ifunky/polydev:latest
	
polydev: ## Run PolyDev shell :-)
	@ docker run -it \
	-v "$$PWD:/data" \
	ifunky/polydev-amplify:latest
