.PHONY: help install build test clean dev deploy-bundle deploy-apps

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

install: ## Install dependencies
	uv sync

build: ## Build the wheel package
	uv build --wheel

test: ## Run tests
	uv run python test_email.py

clean: ## Clean build artifacts
	rm -rf dist/ .build/ src/*.egg-info
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true

dev: ## Start development server with hot reload
	uv run email-server

deploy-bundle: build ## Deploy to Databricks using bundle CLI
	@echo "Deploying to Databricks using bundle..."
	databricks bundle deploy
	databricks bundle run email-mcp-server

deploy-apps: build ## Deploy to Databricks using apps CLI
	@echo "Deploying to Databricks using apps CLI..."
	@if [ -z "$$DATABRICKS_USERNAME" ]; then \
		echo "Getting Databricks username..."; \
		export DATABRICKS_USERNAME=$$(databricks current-user me | jq -r .userName); \
	fi; \
	databricks sync . "/Users/$$DATABRICKS_USERNAME/email-mcp-server" && \
	databricks apps deploy email-mcp-server --source-code-path "/Workspace/Users/$$DATABRICKS_USERNAME/email-mcp-server"

lint: ## Run linting (if available)
	@echo "No linting configured yet"

format: ## Format code (if available)
	@echo "No formatting configured yet"
