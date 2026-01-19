.PHONY: help local-start local-stop local-reset local-logs local-test
.PHONY: tf-init tf-plan tf-apply tf-destroy tf-output
.PHONY: k8s-deploy k8s-delete k8s-status k8s-logs
.PHONY: bootstrap-init bootstrap-apply bootstrap-output

# Default target
.DEFAULT_GOAL := help

# Colors
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

##@ General

help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make $(CYAN)<target>$(NC)\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(CYAN)%-20s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(YELLOW)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Local Development

start: ## Start Keycloak infrastructure
	@echo "$(GREEN)Starting Keycloak infrastructure...$(NC)"
	@docker network create haiintel-network 2>/dev/null || echo "Network already exists"
	@docker compose up -d
	@echo "$(GREEN)✓ Keycloak infrastructure started$(NC)"
	@echo ""
	@echo "$(CYAN)Service URLs:$(NC)"
	@echo "  Keycloak:   http://localhost:8080 (admin/admin)"
	@echo ""
	@echo "$(YELLOW)Note: Make sure shared-infra is running for monitoring$(NC)"
	@echo "  cd ../shared-infra && make start"

stop: ## Stop Keycloak infrastructure
	@echo "$(YELLOW)Stopping Keycloak infrastructure...$(NC)"
	@docker compose down
	@echo "$(GREEN)✓ Keycloak infrastructure stopped$(NC)"

restart: ## Restart Keycloak infrastructure
	@$(MAKE) stop
	@$(MAKE) start

logs: ## View logs from Keycloak stack
	@docker compose logs -f

logs-keycloak: ## View Keycloak logs only
	@docker logs -f haiintel-keycloak

logs-postgres: ## View PostgreSQL logs only
	@docker logs -f haiintel-keycloak-postgres

logs-exporter: ## View PostgreSQL Exporter logs only
	@docker logs -f haiintel-keycloak-postgres-exporter

status: ## Show status of Keycloak containers
	@echo "$(CYAN)Keycloak Infrastructure Status:$(NC)"
	@docker ps --filter "name=haiintel-keycloak" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

clean: ## Remove all containers and volumes
	@echo "$(RED)WARNING: This will remove all Keycloak data!$(NC)"
	@read -p "Are you sure? (yes/no): " -r; \
	if [ "$$REPLY" = "yes" ]; then \
		docker compose down -v; \
		echo "$(GREEN)✓ Cleanup complete$(NC)"; \
	else \
		echo "Cancelled."; \
	fi

health: ## Check health of Keycloak services
	@echo "$(CYAN)Checking service health...$(NC)"
	@echo -n "PostgreSQL: "
	@docker exec haiintel-keycloak-postgres pg_isready -U keycloak > /dev/null 2>&1 && echo "$(GREEN)✓ Healthy$(NC)" || echo "$(RED)✗ Unhealthy$(NC)"
	@echo -n "Keycloak:   "
	@curl -sf http://localhost:8080/health/ready > /dev/null && echo "$(GREEN)✓ Healthy$(NC)" || echo "$(RED)✗ Unhealthy$(NC)"
	@echo -n "PG Exporter:"
	@curl -sf http://localhost:9187/metrics > /dev/null && echo "$(GREEN)✓ Healthy$(NC)" || echo "$(RED)✗ Unhealthy$(NC)"

# Legacy commands for backward compatibility
local-start: start ## (Legacy) Start Keycloak
local-stop: stop ## (Legacy) Stop Keycloak
local-logs: logs ## (Legacy) View logs
local-test: health ## (Legacy) Run health checks

##@ Bootstrap (Run Once)

bootstrap-init: ## Initialize Terraform bootstrap
	@echo "$(GREEN)Initializing Terraform bootstrap...$(NC)"
	@cd terraform/bootstrap && terraform init

bootstrap-apply: ## Apply Terraform bootstrap
	@echo "$(GREEN)Applying Terraform bootstrap...$(NC)"
	@cd terraform/bootstrap && terraform apply

bootstrap-output: ## Show bootstrap outputs
	@cd terraform/bootstrap && terraform output

##@ Terraform

tf-init: ## Initialize Terraform for environment (ENV=dev|staging|prod)
	@if [ -z "$(ENV)" ]; then echo "$(YELLOW)Please specify ENV=dev|staging|prod$(NC)"; exit 1; fi
	@echo "$(GREEN)Initializing Terraform for $(ENV)...$(NC)"
	@cd terraform/environments/$(ENV) && terraform init

tf-plan: ## Plan Terraform changes (ENV=dev|staging|prod)
	@if [ -z "$(ENV)" ]; then echo "$(YELLOW)Please specify ENV=dev|staging|prod$(NC)"; exit 1; fi
	@echo "$(GREEN)Planning Terraform for $(ENV)...$(NC)"
	@cd terraform/environments/$(ENV) && terraform plan

tf-apply: ## Apply Terraform changes (ENV=dev|staging|prod)
	@if [ -z "$(ENV)" ]; then echo "$(YELLOW)Please specify ENV=dev|staging|prod$(NC)"; exit 1; fi
	@echo "$(GREEN)Applying Terraform for $(ENV)...$(NC)"
	@cd terraform/environments/$(ENV) && terraform apply

tf-destroy: ## Destroy Terraform resources (ENV=dev|staging|prod)
	@if [ -z "$(ENV)" ]; then echo "$(YELLOW)Please specify ENV=dev|staging|prod$(NC)"; exit 1; fi
	@echo "$(YELLOW)Destroying Terraform for $(ENV)...$(NC)"
	@cd terraform/environments/$(ENV) && terraform destroy

tf-output: ## Show Terraform outputs (ENV=dev|staging|prod)
	@if [ -z "$(ENV)" ]; then echo "$(YELLOW)Please specify ENV=dev|staging|prod$(NC)"; exit 1; fi
	@cd terraform/environments/$(ENV) && terraform output

##@ Kubernetes

k8s-deploy: ## Deploy Keycloak stack to Kubernetes (ENV=dev|staging|prod)
	@if [ -z "$(ENV)" ]; then echo "$(YELLOW)Please specify ENV=dev|staging|prod$(NC)"; exit 1; fi
	@echo "$(GREEN)Deploying Keycloak stack to $(ENV)...$(NC)"
	@kubectl apply -k kubernetes/manifests/

k8s-delete: ## Delete Keycloak stack from Kubernetes
	@echo "$(YELLOW)Deleting Keycloak stack...$(NC)"
	@kubectl delete -k kubernetes/manifests/

k8s-status: ## Show Kubernetes resources status
	@echo "$(GREEN)Keycloak Stack Status:$(NC)"
	@kubectl get all -n keycloak

k8s-logs: ## View Keycloak logs (POD=pod-name)
	@if [ -z "$(POD)" ]; then \
		kubectl logs -n keycloak -l app=keycloak --tail=100 -f; \
	else \
		kubectl logs -n keycloak $(POD) -f; \
	fi

k8s-port-forward: ## Port forward to Keycloak (local:8080 -> keycloak:8080)
	@echo "$(GREEN)Port forwarding to Keycloak...$(NC)"
	@kubectl port-forward -n keycloak svc/keycloak 8080:80

##@ Setup

setup-keycloak: ## Initialize Keycloak configuration
	@chmod +x scripts/setup/init-keycloak.sh
	@./scripts/setup/init-keycloak.sh

setup-oidc: ## Configure OIDC providers (Google, GitHub)
	@chmod +x scripts/setup/configure-oidc-providers.sh
	@./scripts/setup/configure-oidc-providers.sh

setup-clients: ## Create Keycloak clients
	@chmod +x scripts/setup/create-clients.sh
	@./scripts/setup/create-clients.sh

##@ Utilities

get-aks-credentials: ## Get AKS credentials (ENV=dev|staging|prod)
	@if [ -z "$(ENV)" ]; then echo "$(YELLOW)Please specify ENV=dev|staging|prod$(NC)"; exit 1; fi
	@echo "$(GREEN)Getting AKS credentials for $(ENV)...$(NC)"
	@az aks get-credentials --resource-group rg-haiintel-keycloak-$(ENV) --name haiintel-keycloak-$(ENV)-aks --overwrite-existing

health-check: ## Run health checks
	@chmod +x scripts/operations/health-check.sh
	@./scripts/operations/health-check.sh

clean: ## Clean temporary files
	@echo "$(GREEN)Cleaning temporary files...$(NC)"
	@find . -type f -name "*.tfplan" -delete
	@find . -type f -name "*.tfstate.backup" -delete
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true

