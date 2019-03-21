# Thanks to https://gist.github.com/mpneuried/0594963ad38e68917ef189b4e6a269db

# import config.
# You can change the default config with `make cnf=special.env build`

VERSION ?= ''

cnf ?= .env
include $(cnf)
export $(shell sed 's/=.*//' $(cnf))


# HELP
# ------------------------------------------------------------------------------
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_8-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

.DEFAULT_GOAL := help


# DOCKER TASKS
# ------------------------------------------------------------------------------

BUILD_NAME := $(DOCKER_REPO)/$(NAMESPACE)/$(APP_NAME)

# Build the container
build: ## Build the container
	@docker build -t $(BUILD_NAME) --build-arg VERSION=$(VERSION) -f ./Dockerfile .

build-nc: ## Build the container without caching
	@docker build --no-cache -t $(BUILD_NAME) --build-arg VERSION=$(VERSION) -f ./Dockerfile .

run: ## Run container on port configured in `.env`
	docker run -it --rm -v $(pwd):/apps -v ~/.kube:/root/.kube $(BUILD_NAME)

up: build run ## Run container on port configured in `.env` (Alias to run)

release: build-nc publish ## Make a release by building and publishing `latest` tagged containers to ECR

# Docker publish
publish: publish-latest publish-version ## Publish as `latest` tagged containers to ECR

publish-latest: tag-latest ## Publish the `latest` taged container to ECR
	@echo 'publish latest to $(DOCKER_REPO)'
	@docker push $(BUILD_NAME):latest

publish-version: tag-version ## Publish the `{version}` taged container to ECR
	@echo 'publish $(VERSION) to $(DOCKER_REPO)'
	@docker push $(BUILD_NAME):$(VERSION)

# Docker tagging
tag: tag-latest tag-version ## Generate container tags for the `latest` tags

tag-latest: ## Generate container latest tag
	@echo 'create tag latest'
	@docker tag $(BUILD_NAME) $(BUILD_NAME):latest

tag-version: ## Generate container `latest` tag
	@echo 'create tag $(version)'
	@docker tag $(BUILD_NAME) $(BUILD_NAME):$(VERSION)

