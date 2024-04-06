#!make
SHELL = /bin/sh

### Description
### you can use triple number sign as prefix for hidden comment
### double number sign will be used in help command as beginning of comment

ifeq ("$(wildcard ./docker/.env)","")
$(info docker .env is not exist, trying create it)
$(shell cp ./docker/.env.dev ./docker/.env)
endif

ifeq ("$(wildcard ./http-client.env.json)","")
$(info http-client.env.json is not exist, trying create it)
$(shell cp ./_http-client.env.json ./http-client.env.json)
endif

include ./docker/.env

export $(shell sed 's/=.*//' ./docker/.env)

export MINIMUM_DOCKER_VERSION=24
export DOCKER_VERSION=$(shell docker -v | grep -oE '([0-9]+)(\.[0-9]{1,3})+' | cut -d '.' -f 1)
ifeq ($(shell expr $(MINIMUM_DOCKER_VERSION) \> $(DOCKER_VERSION)),1)
$(error It seems like docker version is not supported by this application. The minimum docker version is $(MINIMUM_DOCKER_VERSION))
endif

export COMPOSE_PROJECT_NAME=${PROJECT_NAME}

DOCKER_COMPOSE = docker compose -f ./docker/docker-compose.yaml
DOCKER_EXEC_APP = docker exec -it ${PROJECT_NAME}_php
DOCKER_EXEC_NGINX = docker exec -it ${PROJECT_NAME}_nginx
DOCKER_EXEC_REDIS = docker exec -it ${PROJECT_NAME}_redis
XDEBUG_OPTS:=export PHP_IDE_CONFIG=\"$(PHP_IDE_CONFIG)\" XDEBUG_SESSION=1
PHP_EXECUTOR=php
PHP_RUNNER=$(XDEBUG_OPTS) && $(PHP_EXECUTOR)
SYMFONY_CONSOLE = $(PHP_RUNNER) bin/console
DOCKER_EXEC_APP_PHP = $(DOCKER_EXEC_APP) bash -c
COMPOSER = ${DOCKER_EXEC_APP} composer

export USER_ID=$(shell id -u)
export GROUP_ID=$(shell id -g)
export LOCALHOST_IP_ADDRESS=$(shell ip addr show | grep "\binet\b.*\bdocker0\b" | awk '{print $$2}' | cut -d '/' -f 1)
ifndef LOCALHOST_IP_ADDRESS
$(error It seems like docker is not started yet, because docker IP is empty, please try restart docker with: sudo systemctl restart docker)
endif

# Misc
.DEFAULT_GOAL=help

## —— 🎵 🐳 The Symfony Docker Makefile 🐳 🎵 ——————————————————————————————————
help:   ## Show this help.
	@grep -E '^([a-zA-Z_-]+:.*?##)|(^##)[^#]*$$' Makefile \
       | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-25s\033[0m %s\n", $$1, $$2}' \
       | sed -e 's/\[32m##\(.*\)$/\1/\[33m\n/g' \
       | sed -e 's/:.*\##//'

install: pre-install down build up post-install ## Create and start docker hub
pre-install:
	@echo --- Pre-install ---
	rm -f ./.env.local.php
	mkdir -p ./logs/
	chmod g+s ./logs/
	mkdir -p $(addprefix './logs/', 'db' 'nginx' 'php')
	mkdir -p $(addprefix './logs/php/', 'xdebug' 'xhprof' 'xtrace')
	find ./logs -type d -exec chmod g+s {} \;
post-install: composer-install composer-dump-env-dev migrate-up
docker-dump-env-dev: ## Docker env for dev environment
	rm -f ./docker/.env
	cp "./docker/.env.dev" "./docker/.env"
build: ## Build containers, e.g.: make build / make build c=nginx
	$(eval c?=)
	${DOCKER_COMPOSE} build $(c)
build-no-cache: ## Build containers without cache, e.g.: make build-no-cache / make build-no-cache c=nginx
	$(eval c?=)
	${DOCKER_COMPOSE} build --no-cache $(c)
rebuild: down build up composer-clear-cache composer-dump-env-dev ## Use it if you have changes in containers or Dockerfile.
rebuild-dev: docker-dump-env-dev rebuild ## Remove env & rebuild (using .env.dev)
restart: down up ## Recreates containers
rebase: rebuild post-install sf-cc refactor-cc ## After rebasing project
up: ## Start the docker hub, e.g.: make up / make up c=php
	@$(eval c?=)
	@$(eval command=$(if $(c:=), up $(c), up -d))
	${DOCKER_COMPOSE} $(command)
down: ## Stop the docker hub, e.g.: make down / make down c=php
	@$(eval c?=)
	@$(eval command=$(if $(c:=), rm -f -s $(c), down))
	${DOCKER_COMPOSE} $(command)
stop: down ## Same as 'make down'
ps: ## -
	${DOCKER_COMPOSE} ps

## ——  Working with migrations  ——————————————————————————————————
migrate-up: ## Use additional option for upping certain migration, e.g.: make migrate-up v=123'
	@$(eval v?=)
	@$(eval version=$(if $(v:=), 'DoctrineMigrations\Version$(v)',))
	${DOCKER_EXEC_APP_PHP} "${SYMFONY_CONSOLE} doctrine:migrations:migrate --no-interaction $(version)"
migrate-down: ## Use additional option for upping certain migration, e.g.: make migrate-down v=123
	@$(eval v?=)
	@$(eval version=$(if $(v:=), 'DoctrineMigrations\Version$(v)', $(error Migrations number is not set, example: make migrate-down v=123)))
	${DOCKER_EXEC_APP_PHP} "${SYMFONY_CONSOLE} doctrine:migrations:execute --down --no-interaction $(version)"
migrate-down-current: ## Downgrade last executed migration
	${DOCKER_EXEC_APP_PHP} "${SYMFONY_CONSOLE} doctrine:migrations:current | sed -E 's/.*Version([0-9]*)/\1/g' | xargs -I{} php bin/console doctrine:migrations:execute --down --no-interaction DoctrineMigrations\\\Version{}"

# Fixture
fixtures-load:
	${DOCKER_EXEC_PHP} php bin/console doctrine:fixtures:load
migrate-prev: ## -
	${DOCKER_EXEC_APP_PHP} "${SYMFONY_CONSOLE} doctrine:migrations:migrate prev"
migrate-next: ## -
	${DOCKER_EXEC_APP_PHP} "${SYMFONY_CONSOLE} doctrine:migrations:migrate next"
migration: ## -
	${DOCKER_EXEC_APP_PHP} "${SYMFONY_CONSOLE} doctrine:migrations:generate"
migrate-diff: ## -
	${DOCKER_EXEC_APP_PHP} "${SYMFONY_CONSOLE} doctrine:migrations:diff --no-interaction"
migrate-drop: ## -
	${DOCKER_EXEC_APP_PHP} "${SYMFONY_CONSOLE} doctrine:schema:drop --full-database --force"
migrate-status: ## -
	${DOCKER_EXEC_APP_PHP} "${SYMFONY_CONSOLE} doctrine:migrations:status"
migrate-list: ## -
	${DOCKER_EXEC_APP_PHP} "${SYMFONY_CONSOLE} doctrine:migrations:list"
migrate-make: ## Generate migration by project entities
	${DOCKER_EXEC_APP_PHP} "${SYMFONY_CONSOLE} make:migration"

## —— 🍦 Application 🍦 ——————————————————————————————————
exec: ## Exec command inside the app, e.g.: make exec c="ping -c4 127.0.0.1"
	@$(eval c?=)
	@$(eval command =$(if $(c:=), , $(error Command is not set, example: make exec c="ping -c4 127.0.0.1")))
	${DOCKER_EXEC_APP} $(c)
bash: ## Entering inside docker PHP container
	${DOCKER_EXEC_APP} bash
nginx: ## Entering inside docker NGINX container
	${DOCKER_EXEC_NGINX} ash
log:
	@$(eval c?=)
	@$(eval command =$(if $(c:=), , $(error Container is not set, example: make exec c="nginx")))
	docker logs dester_ebay_$(c) -f

test: ## Run unit tests
	@$(eval c?=)
	@$(eval o?=)
	@$(eval options=$(if $(o:=), $(o), --display-errors --stop-on-defect))
	@$(eval selectedTest=$(if $(c:=), --filter $(c),))
	@${DOCKER_EXEC_REDIS} redis-cli -n 0 FLUSHDB > /dev/null
	${DOCKER_EXEC_APP_PHP} "${PHP_RUNNER} vendor/bin/phpunit $(options) $(selectedTest)"
lint: lint-containers lint-translations ## Run linters
lint-containers: ## Run linters
	${DOCKER_EXEC_APP_PHP} "${SYMFONY_CONSOLE} lint:container"
lint-translations:
	${DOCKER_EXEC_APP_PHP} "${SYMFONY_CONSOLE} lint:yaml translations"
cc: sf-cc composer-dump-autoload ## Clear symfony cache and update autoload

## —— Composer 🧙 ——————————————————————————————————————————————————————————————
composer: ## Run composer, pass the parameter "c=" to run a given command, example: make composer c='req symfony/orm-pack'
	@$(eval c?=)
	$(if $(c:=), , $(error Command is not set, example: "make composer c='require ***/***'"))
	$(COMPOSER) $(c)
composer-install: ## Install composer to project
	$(COMPOSER) install --ignore-platform-reqs \
                        --no-interaction \
                        --no-scripts
composer-hard-install: composer-vendor-drop composer-clear-cache composer-install ## Hard install composer to project (with deleting vendor dir)
composer-version: ## Current version of composer
	$(COMPOSER) --version
composer-clear-cache: ## Clear composer cache
	$(COMPOSER) clear-cache
composer-dump-autoload: ## Update the composer autoloader because of new classes in a classmap package
	$(COMPOSER) dump-autoload
composer-dump-env-dev: ## Recreate env php files
	$(COMPOSER) dump-env dev
composer-dump-env-test: ## Recreate env php files
	$(COMPOSER) dump-env test
composer-update: ## -
	$(COMPOSER) update
composer-update-full: ## Upgrades, downgrades and removals for packages currently locked to specific versions.
	$(COMPOSER) update --with-all-dependencies
composer-update-lock: ## -
	$(COMPOSER) update --lock
composer-vendor-drop: ## Delete vendor directory with all packages
	rm -rf vendor

## —— Symfony 🎵 ———————————————————————————————————————————————————————————————
sf: ## List all Symfony commands or pass the parameter "c=" to run a given command, example: make sf c=about
	@$(eval c?=)
	${DOCKER_EXEC_APP_PHP} "${SYMFONY_CONSOLE} $(c)"
sf-cc: ## Clear cache
	${DOCKER_EXEC_APP_PHP} "${SYMFONY_CONSOLE} cache:clear"
sf-controller: ## Create Symfony controller use parameter name "n=" to run a given command, example: make sf-controller n=AccountController
	@$(eval n?=)
	$(if $(n:=),,$(error Controller name is not set, example: "make sf-controller n=AccountController"))
	${DOCKER_EXEC_APP_PHP} "${SYMFONY_CONSOLE} make:controller $(n)"
sf-entity: ## Create Symfony entities, use parameter "n=" to run a given command, example: make sf-entity n=Address
	@$(eval n?=)
	$(if $(n:=),,$(error Entity name is not set, example: "make sf-entity n=Address"))
	${DOCKER_EXEC_APP_PHP} "${SYMFONY_CONSOLE} make:entity $(n)"
sf-form: ## Create Symfony form, example: make sf-form
	${DOCKER_EXEC_APP_PHP} "${SYMFONY_CONSOLE} make:form"
sf-messenger: ## Start messenger consumes, do not use on production server! Because log duplicating
	${DOCKER_EXEC_APP_PHP} "${SYMFONY_CONSOLE} enqueue:consume --setup-broker -vvv"
sf-entity-validation: ## Doctrine schema validation
	${DOCKER_EXEC_APP_PHP} "${SYMFONY_CONSOLE} doctrine:schema:validate"
sf-translation: ## Add translation file, example: make sf-translation c=en. Use "d" for setting certain domain name
	@$(eval c?=)
	@$(eval d?=)
	@$(eval domain=$(if $(d:=), --domain=$(d),))
	${DOCKER_EXEC_APP_PHP} "${SYMFONY_CONSOLE} translation:extract --force $(domain) --format=yaml $(c)"

pusher: lint refactor
refactor: ## Code refactoring with code analysis
	@$(eval o?=)
	@$(eval options=$(if $(o:=), $(o), ))
	${DOCKER_EXEC_APP_PHP} "${PHP_EXECUTOR} vendor/bin/rector process $(options)"

refactor-cc:  ## Code refactoring without cache, run it if you break previous start of script
	@make refactor o='--clear-cache'

refactor-dry:  ## Code refactoring, with dry-run option
	@make refactor o='--dry-run'
