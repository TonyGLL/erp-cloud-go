ENV_FILE := .env.local

ifneq (,$(wildcard $(ENV_FILE)))
	include $(ENV_FILE)
	export
endif

COMPOSE := docker compose --env-file $(ENV_FILE)
MIGRATIONS_DIR := migrations
DATABASE_URL := postgresql://$(DATABASE_USER):$(DATABASE_PASSWORD)@$(DATABASE_HOST):$(DATABASE_PORT)/$(DATABASE_NAME)?sslmode=$(DATABASE_SSLMODE)

.PHONY: build run test watch up-dev up-prod down db-up db-down db-logs db-reset

# Build the Go application
build:
	@echo "Building..."
	@go build -o main cmd/server/main.go

# Run the Go application for development
depends-on: build
run:
	@echo "Running in development mode..."
	@CONFIG_FILE=local.env go run cmd/server/main.go

# Run tests
test:
	@echo "Testing..."
	@go test -v ./...

# Live Reload
watch:
	@if command -v air > /dev/null; then \
	    CONFIG_FILE=local.env air; \
	    echo "Watching...";\
	else \
	    read -p "Go's 'air' is not installed on your machine. Do you want to install it? [Y/n] " choice; \
	    if [ "$$choice" != "n" ] && [ "$$choice" != "N" ]; then \
	        go install github.com/air-verse/air@latest; \
	        CONFIG_FILE=local.env air; \
	        echo "Watching...";\
	    else \
	        echo "You chose not to install air. Exiting..."; \
	        exit 1; \
	    fi; \
	fi

db-up:
	$(COMPOSE) up -d postgres

db-down:
	$(COMPOSE) down

db-logs:
	$(COMPOSE) logs -f postgres

db-reset:
	$(COMPOSE) down -v
	$(COMPOSE) up -d postgres

.PHONY: migrate-up
migrate-up:
	migrate \
		-path $(MIGRATIONS_DIR) \
		-database "$(DATABASE_URL)" \
		up


.PHONY: migrate-down
migrate-down:
	migrate \
		-path $(MIGRATIONS_DIR) \
		-database "$(DATABASE_URL)" \
		down 1


.PHONY: migrate-version
migrate-version:
	migrate \
		-path $(MIGRATIONS_DIR) \
		-database "$(DATABASE_URL)" \
		version

.PHONY: migrate-create
migrate-create:
	@if [ -z "$(name)" ]; then \
		echo "Usage: make migrate-create name=add_phone_to_clients"; \
		exit 1; \
	fi
	migrate create -ext sql -dir $(MIGRATIONS_DIR) -seq $(name)

# Docker-compose commands
up-local:
	@echo "Starting local environment..."
	@CONFIG_FILE=local.env docker compose up --build d

up-dev:
	@echo "Starting development environment..."
	@CONFIG_FILE=dev.env docker compose up --build -d

up-prod:
	@echo "Starting production environment..."
	@CONFIG_FILE=prod.env docker compose up --build -d

down:
	@echo "Stopping docker compose environment..."
	@docker compose down
