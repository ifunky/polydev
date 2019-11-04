.SHELL := /usr/bin/bash

help:
	@grep -E '^[a-zA-Z_-_\/]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build: ## Build docker file
	@docker build -t ifunky/polydev:latest .

build/nocache: ## Rebuild with no cache to force fresh rebuild
	@docker build --no-cache -t ifunky/polydev:latest .

publish: ## Publish to Dockerhub
	@docker push ifunky/polydev:latest

polydev: ## Run PolyDev shell :-)
	@ docker run -it \
	--user "$$(id -u):$$(id -g)" \
	-v "$$PWD:/data" \
	ifunky/polydev:latest