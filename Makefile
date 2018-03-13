
PROJECT_NAME ?= remindmebackend
ORG_NAME ?= wsoyinka
REPO_NAME ?= remindmebackend

DEV_COMPOSE_FILE := docker/dev/docker-compose.yml
RELEASE_COMPOSE_FILE := docker/release/docker-compose.yml

RELEASE_PROJECT := $(PROJECT_NAME)$(BUILD_ID)
DEV_PROJECT := $(RELEASE_PROJECT)dev


.PHONY: test test2 build release clean


test:
	$(INFO) "Building images..."
	@docker-compose -p $(DEV_PROJECT)  -f $(DEV_COMPOSE_FILE) build
	$(INFO) "Wait for Test database service to be ready before proceeding..."
	@docker-compose -p $(DEV_PROJECT)  -f $(DEV_COMPOSE_FILE) up agent
	$(INFO) "Run tests..."
	@docker-compose -p $(DEV_PROJECT)  -f $(DEV_COMPOSE_FILE) up test
	@ docker cp $$(docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) ps -q test):/reports/. reports
	$(INFO) "Testing complete!!"

2test2:
	$(INFO) "Sup with 2tests "
	$(INFO) "Sup with 2tests "
	$(INFO)  "docker cp $$(docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) ps -q test):/reports/. jennnn"

build:
	$(INFO) "Building Application Artifacts using builder service..."
	@docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) up builder
	${INFO} "Coping artifacts to target folder..."
	@docker cp $$(docker-compose -p $(DEV_PROJECT) -f $(DEV_COMPOSE_FILE) ps -q builder):/wheelhouse/.  target
	$(INFO) "Build complete!!"

release:
	${INFO} "Building images...using $(RELEASE_COMPOSE_FILE)"
	@docker-compose -p $(RELEASE_PROJECT)  -f $(RELEASE_COMPOSE_FILE) build
	${INFO} "Wait for Release Database service to be ready before proceeding..."
	@docker-compose -p $(RELEASE_PROJECT)  -f $(RELEASE_COMPOSE_FILE) up agent
	${INFO} "Collecting static files.."
	@docker-compose -p $(RELEASE_PROJECT)  -f $(RELEASE_COMPOSE_FILE) run --rm app manage.py collectstatic --noinput
	${INFO} "Running database migrations..."
	@docker-compose -p $(RELEASE_PROJECT)  -f $(RELEASE_COMPOSE_FILE) run --rm app manage.py migrate --noinput
	${INFO} "Running acceptance test..."
	@docker-compose -p $(RELEASE_PROJECT)  -f $(RELEASE_COMPOSE_FILE) up test
	@ docker cp $$(docker-compose -p $(RELEASE_PROJECT) -f $(RELEASE_COMPOSE_FILE) ps -q test):/reports/. reports
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





