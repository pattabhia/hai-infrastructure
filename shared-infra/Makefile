.PHONY: help start stop restart logs status clean

# Default target
.DEFAULT_GOAL := help

# Colors
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make $(CYAN)<target>$(NC)\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(CYAN)%-15s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(YELLOW)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

start: ## Start shared infrastructure (Prometheus, Grafana)
	@echo "$(GREEN)Starting HAI Intel shared infrastructure...$(NC)"
	@docker network create haiintel-network 2>/dev/null || echo "Network already exists"
	@docker compose up -d
	@echo "$(GREEN)✓ Shared infrastructure started$(NC)"
	@echo ""
	@echo "$(CYAN)Service URLs:$(NC)"
	@echo "  Prometheus: http://localhost:9090"
	@echo "  Grafana:    http://localhost:3000 (admin/admin)"

stop: ## Stop shared infrastructure
	@echo "$(YELLOW)Stopping shared infrastructure...$(NC)"
	@docker compose down
	@echo "$(GREEN)✓ Shared infrastructure stopped$(NC)"

restart: ## Restart shared infrastructure
	@$(MAKE) stop
	@$(MAKE) start

logs: ## View logs
	@docker compose logs -f

logs-prometheus: ## View Prometheus logs
	@docker logs -f haiintel-prometheus

logs-grafana: ## View Grafana logs
	@docker logs -f haiintel-grafana

status: ## Show status of services
	@echo "$(CYAN)Shared Infrastructure Status:$(NC)"
	@docker ps --filter "name=haiintel-prometheus" --filter "name=haiintel-grafana" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

clean: ## Remove all containers, networks, and volumes
	@echo "$(RED)WARNING: This will remove all monitoring data!$(NC)"
	@read -p "Are you sure? (yes/no): " -r; \
	if [ "$$REPLY" = "yes" ]; then \
		docker compose down -v; \
		echo "$(GREEN)✓ Cleanup complete$(NC)"; \
	else \
		echo "Cancelled."; \
	fi

health: ## Check health of services
	@echo "$(CYAN)Checking service health...$(NC)"
	@echo -n "Prometheus: "
	@curl -sf http://localhost:9090/-/healthy > /dev/null && echo "$(GREEN)✓ Healthy$(NC)" || echo "$(RED)✗ Unhealthy$(NC)"
	@echo -n "Grafana:    "
	@curl -sf http://localhost:3000/api/health > /dev/null && echo "$(GREEN)✓ Healthy$(NC)" || echo "$(RED)✗ Unhealthy$(NC)"

