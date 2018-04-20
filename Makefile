
PROJECT_NAME ?= remindmebackend
ORG_NAME ?= wsoyinka
REPO_NAME ?= remindmebackend

DEV_COMPOSE_FILE := docker/dev/docker-compose.yml
RELEASE_COMPOSE_FILE := docker/release/docker-compose.yml

RELEASE_PROJECT := $(PROJECT_NAME)$(BUILD_ID)
DEV_PROJECT := $(RELEASE_PROJECT)dev


APP_SERVICE_NAME := app

INSPECT := $$(docker-compose -p $$1 -f $$2 ps -q $$3 | xargs -I ARGS docker inspect -f "{{ .State.ExitCode  }}" ARGS)

CHECK := @bash -c '\
	if [[ $(INSPECT) -ne 0 ]]; \
 	then exit $(INSPECT); fi' VALUE

## VALUE above is the text following call to the $CHECK variable or ARG1. Can easily be VALUE1 VALUE2 VALUE2 if applicable 


DOCKER_REGISTRY ?= docker.io

DOCKER_REGISTRY_AUTH ?=

.PHONY: test test2 build release clean tag buildtag login logout publish


test:
	$(INFO) "Pulling latest images..."
#	@docker-compose -p $(DEV_PROJECT)  -f $(DEV_COMPOSE_FILE) pull
	$(INFO) "Building images..."
	@docker-compose -p $(DEV_PROJECT)  -f $(DEV_COMPOSE_FILE) build --pull test
#	@docker-compose -p $(DEV_PROJECT)  -f $(DEV_COMPOSE_FILE) build cache
	$(INFO) "Wait for Test database service to be ready before proceeding..."
	@ docker-compose -p $(DEV_PROJECT)  -f $(DEV_COMPOSE_FILE) run --rm  agent
	$(INFO) "Run tests..."
	@docker-compose -p $(DEV_PROJECT)  -f $(DEV_COMPOSE_FILE) up test
	@ docker cp $$(docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) ps -q test):/reports/. reports
	${CHECK} $(DEV_PROJECT) $(DEV_COMPOSE_FILE) test
	@docker-compose -p $(DEV_PROJECT)  -f $(DEV_COMPOSE_FILE) rm -s -f db
	$(INFO) "Testing complete!!"

2test2:
	$(INFO) "Sup with 2tests "
	$(INFO) "Sup with 2tests "
	$(INFO)  "docker cp $$(docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) ps -q test):/reports/. jennnn"

build:
	$(INFO) "Building Application Artifacts using builder service..."
	@docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) up builder
	${CHECK} $(DEV_PROJECT)  $(DEV_COMPOSE_FILE) builder
	${INFO} "Coping artifacts to target folder..."
	@docker cp $$(docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) ps -q builder):/wheelhouse/.  target
	$(INFO) "Build complete!!"

release:
	${INFO} "Building images...using $(RELEASE_COMPOSE_FILE)"
	@docker-compose -p $(RELEASE_PROJECT)  -f $(RELEASE_COMPOSE_FILE) build
	${INFO} "Wait for Release Database service to be ready before proceeding..."
	@docker-compose -p $(RELEASE_PROJECT)  -f $(RELEASE_COMPOSE_FILE) run --rm agent
	${INFO} "Collecting static files.."
	@docker-compose -p $(RELEASE_PROJECT)  -f $(RELEASE_COMPOSE_FILE) run --rm app manage.py collectstatic --noinput
	${INFO} "Running database migrations..."
	@docker-compose -p $(RELEASE_PROJECT)  -f $(RELEASE_COMPOSE_FILE) run --rm app manage.py migrate --noinput
	${INFO} "Running acceptance test..."
	@docker-compose -p $(RELEASE_PROJECT)  -f $(RELEASE_COMPOSE_FILE) up test
	@ docker cp $$(docker-compose -p $(RELEASE_PROJECT) -f $(RELEASE_COMPOSE_FILE) ps -q test):/reports/. reports
	${CHECK} $(RELEASE_PROJECT) $(RELEASE_COMPOSE_FILE) test
	${INFO} "Acceptance tesing complete"

clean:
	${INFO} "Destroying the development Environment in $(DEV_COMPOSE_FILE)..."
	@docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) kill
	@docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) rm -f -v
	${INFO} "Destroying the release Environment in $(RELEASE_COMPOSE_FILE)..."
	@docker-compose -p $(RELEASE_PROJECT) -f $(RELEASE_COMPOSE_FILE) kill
	@docker-compose -p $(RELEASE_PROJECT) -f $(RELEASE_COMPOSE_FILE) rm -f -v 
	${INFO} "Clean up dangling images ...."
	@docker images -q -f dangling=true -f label=application=$(REPO_NAME) | xargs -I ARGS docker rmi -f ARGS
	${INFO} "Clean up complete !!"


login:
	${INFO} "Login to Docker Registry $$DOCKER_REGISTRY.."
	docker login -u $$DOCKER_USER  -p $$DOCKER_PASSWORD  $(DOCKER_REGISTRY_AUTH)
	${INFO} "Logged in to Docker registry $$DOCKER_REGISTRY" 

logout:
	${INFO} "Logout of Docker registry $$DOCKER_REGISTRY..."
	@ docker logout
	${INFO} "Logged out of Docker registry $$DOCKER_REGISTRY"

publish:
	${INFO} "Publish release image $(IMAGE_ID) to $(DOCKER_REGISTRY)/$(ORG_NAME)/$(REPO_NAME)..."
	echo "hello world $(REPO_EXPR)"
	@ $(foreach tag,$(shell echo $(REPO_EXPR)), docker push $(tag);)
#	$(shell echo $(REPO_EXPR))  ####---> will return a list of tags added using make tag and make buildtag ###
#$(foreach tag,$(shell echo $(REPO_EXPR)), docker push $(tag);)
	${INFO} "Publish Done !!"

APP_CONTAINER_ID := $$(docker-compose -p $(RELEASE_PROJECT) -f $(RELEASE_COMPOSE_FILE) ps -q $(APP_SERVICE_NAME) )


# Get image id from built application service - aka app.  See release docker-compose file definition
IMAGE_ID := $$( docker inspect -f  '{{ .Image }}' $(APP_CONTAINER_ID)) 

ifeq ($(DOCKER_REGISTRY), docker.io)
  REPO_FILTER := $(ORG_NAME)/$(REPO_NAME)[^[:space:]|\$$]*
else
  REPO_FILTER := $(DOCKER_REGISTRY)/$(ORG_NAME)/$(REPO_NAME)[^[:space:]|\$$]*
endif


REPO_EXPR := $$(docker inspect -f '{{ range .RepoTags }} {{.}} {{end}}' $(IMAGE_ID) | grep -oh "$(REPO_FILTER)" | xargs   )

tag:
	${INFO} "Tagging release image with tags $(TAG_ARGS)"
	$(foreach tag,$(TAG_ARGS), docker tag $(IMAGE_ID) $(DOCKER_REGISTRY)/$(ORG_NAME)/$(REPO_NAME):$(tag);)
	${INFO} "Tagging Complete!!"
buildtag:
	${INFO} "Tagging final release image with suffix $(BUILD_TAG) and build tags $(BUILDTAG_ARGS)....."
	$(foreach tag,$(BUILDTAG_ARGS), docker tag $(IMAGE_ID) $(DOCKER_REGISTRY)/$(ORG_NAME)/$(REPO_NAME):$(tag)_$(BUILD_TAG);)
	${INFO} "Tagging Final release Complete!!"

tag2:
	${INFO} "Tagging release image with tags $(TAG_ARGS)..."
	@ $(foreach tag,$(TAG_ARGS), docker tag -f $(IMAGE_ID) $(DOCKER_REGISTRY)/$(ORG_NAME)/$(REPO_NAME):$(tag);)
	${INFO} "Tagging complete"

tag3:
	${INFO} "Tagging release image with tags $(TAG_ARGS)..."
	@ $(foreach tag,$(TAG_ARGS), docker tag -f $(IMAGE_ID) $(DOCKER_REGISTRY)/$(ORG_NAME)/$(REPO_NAME):$(tag);)
	${INFO} "Tagging complete"

# make's foreach
# tag = current item
# $(TAGS_ARGS) is list of items
#  docker tag ..... is the action to be performed on each item in list
#  e.g. docker tag <image id> <registry>/<org>/remindmebackend:0.1 
#  e.g. docker tag <image id> <registry>/<org>/remindmebackend:master


### ## wordlist 3 returns the list of words in MAKECMDGOALS from position 3 to the total word count
###  e.g "MAKECMDGOALS = tag 0.1 67  master"  will return:
####   67  master

###  ## check if first word in makecmdgoals is tag
##### if 1st word is tag then use wordlist function combined with words function to extract ALL words following "make tag" into TAG_ARGS variable

ifeq (tag, $(firstword $(MAKECMDGOALS))) ## check if first word in makecmdgoals is tag
  TAG_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS)) ##  words returns the word count of MAKECMDGOALS. ### wordlist returns the list of works in makecmdgoals from position 2 to the total word count
  ifeq ($(TAG_ARGS),)
    $(error You must specifiy a tag)
  endif
  $(eval $(TAG_ARGS):;@:)    ## do not interprete 0.2 bobjoetag  as make taget files
endif


BUILD_TAG_EXPRESSION ?= date -u +%Y%m%d%H%M%S

BUILD_EXPRESSION := $(shell $(BUILD_TAG_EXPRESSION))

## Provide way to override or supplie BUILD_TAG from ENv or from 3rd party build system - jenkins etc
BUILD_TAG ?= $(BUILD_EXPRESSION)


ifeq (buildtag, $(firstword $(MAKECMDGOALS)))  ## check if first workd in makecmdgoals is buildtag
  BUILDTAG_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  ifeq ($(BUILDTAG_ARGS),)
    $(ERROR - You must specifiy a build TAG)
  endif
  $(eval $(BUILDTAG_ARGS):;@:)
endif
   


#e.g, make tag 0.1 foobar
## then
### $(MAKECMDGOALS) = tag 0.1 foobar
### and 
####  $(firstword $(MAKECMDGOALS)) = tag



titi:
	${INFO} 'echo "hello world"'
	echo "hello world"
	echo $(hellow world)
	@echo `ls`
	@echo $$(ls)


YELLOW := "\e[1;33m"
NC := "\e[0m"


INFO := @bash -c '\
	printf $(YELLOW); \
	echo "=> $$1" ; \
	printf $(NC)' VALUE





