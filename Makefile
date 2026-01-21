.PHONY: help start stop status clean logs port-check build deploy check-tools install-tools

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)E-Commerce Polyrepo - Minikube Commands$(NC)"
	@echo "$(YELLOW)Using PostgreSQL port 5433 to avoid conflicts with propel-gtm$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Run 'make check-tools' to verify required tools are installed$(NC)"

check-tools: ## Check if required tools are installed
	@echo "$(BLUE)Checking required tools...$(NC)"
	@command -v minikube >/dev/null 2>&1 && echo "$(GREEN)✓ minikube is installed$(NC)" || echo "$(YELLOW)✗ minikube is NOT installed$(NC)"
	@command -v kubectl >/dev/null 2>&1 && echo "$(GREEN)✓ kubectl is installed$(NC)" || echo "$(YELLOW)✗ kubectl is NOT installed$(NC)"
	@command -v docker >/dev/null 2>&1 && echo "$(GREEN)✓ docker is installed$(NC)" || echo "$(YELLOW)✗ docker is NOT installed$(NC)"
	@command -v skaffold >/dev/null 2>&1 && echo "$(GREEN)✓ skaffold is installed (optional)$(NC)" || echo "$(YELLOW)✗ skaffold is NOT installed (optional)$(NC)"
	@command -v tilt >/dev/null 2>&1 && echo "$(GREEN)✓ tilt is installed (optional)$(NC)" || echo "$(YELLOW)✗ tilt is NOT installed (optional)$(NC)"
	@echo ""
	@echo "$(BLUE)To install missing tools, run: make install-tools$(NC)"

install-tools: ## Show installation commands for required tools
	@echo "$(BLUE)Installation commands for macOS (using Homebrew):$(NC)"
	@echo ""
	@echo "$(GREEN)Required tools:$(NC)"
	@echo "  brew install minikube"
	@echo "  brew install kubectl"
	@echo "  brew install docker"
	@echo ""
	@echo "$(GREEN)Optional tools (for development):$(NC)"
	@echo "  brew install skaffold"
	@echo "  brew install tilt"
	@echo ""
	@echo "$(YELLOW)After installation, run 'make check-tools' to verify$(NC)"

port-check: ## Check for port conflicts with propel-gtm
	@echo "$(BLUE)Checking for port conflicts...$(NC)"
	@if lsof -i :5432 > /dev/null 2>&1; then \
		echo "$(YELLOW)⚠️  Port 5432 is in use (likely propel-gtm PostgreSQL)$(NC)"; \
		echo "$(GREEN)✓ E-commerce will use port 5433 instead$(NC)"; \
	else \
		echo "$(GREEN)✓ Port 5432 is available$(NC)"; \
	fi
	@echo ""
	@echo "$(BLUE)E-commerce ports:$(NC)"
	@echo "  PostgreSQL:  5433 (host) → 5432 (container)"
	@echo "  Redis:       6379"
	@echo "  Frontend:    3000"
	@echo "  API Gateway: 8080"

start: ## Start minikube and deploy all services
	@echo "$(BLUE)Starting minikube...$(NC)"
	minikube start
	@echo "$(BLUE)Applying Kubernetes manifests...$(NC)"
	kubectl apply -f k8s/
	@echo "$(GREEN)✓ Services deployed!$(NC)"
	@echo ""
	@echo "$(YELLOW)Run 'make status' to check deployment status$(NC)"

start-infra-only: ## Start minikube and deploy only infrastructure (postgres, redis)
	@echo "$(BLUE)Starting minikube...$(NC)"
	minikube start
	@echo "$(BLUE)Applying infrastructure manifests only...$(NC)"
	kubectl apply -f k8s-infra/
	@echo "$(GREEN)✓ Infrastructure deployed (PostgreSQL, Redis)!$(NC)"
	@echo ""
	@echo "$(YELLOW)Use this when application Docker images haven't been built yet$(NC)"
	@echo "$(YELLOW)Run 'make status' to check deployment status$(NC)"

stop: ## Stop all services (keeps minikube running)
	@echo "$(BLUE)Stopping services...$(NC)"
	kubectl delete namespace ecommerce
	@echo "$(GREEN)✓ Services stopped$(NC)"

stop-minikube: ## Stop minikube completely
	@echo "$(BLUE)Stopping minikube...$(NC)"
	minikube stop
	@echo "$(GREEN)✓ Minikube stopped$(NC)"

status: ## Check status of all services
	@echo "$(BLUE)Checking service status...$(NC)"
	@kubectl get pods -n ecommerce
	@echo ""
	@echo "$(BLUE)Service endpoints:$(NC)"
	@kubectl get svc -n ecommerce

logs: ## View logs from all services
	@echo "$(BLUE)Fetching logs...$(NC)"
	@echo "Use: kubectl logs -f <pod-name> -n ecommerce"
	@kubectl get pods -n ecommerce

clean: ## Clean up everything (including minikube)
	@echo "$(BLUE)Cleaning up...$(NC)"
	kubectl delete namespace ecommerce || true
	minikube delete
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

build: ## Build Docker images for all services
	@echo "$(BLUE)Building Docker images...$(NC)"
	@eval $$(minikube docker-env)
	docker build -t ecommerce-frontend:latest -f ../fe-nextjs/Dockerfile.dev ../fe-nextjs
	docker build -t ecommerce-api-gateway:latest -f ../be-api-gin/Dockerfile.dev ../be-api-gin
	docker build -t ecommerce-user-service:latest -f ../svc-user-django/Dockerfile.dev ../svc-user-django
	docker build -t ecommerce-listing-service:latest -f ../svc-listing-spring/Dockerfile.dev ../svc-listing-spring
	docker build -t ecommerce-inventory-service:latest -f ../svc-inventory-rails/Dockerfile.dev ../svc-inventory-rails
	@echo "$(GREEN)✓ All images built$(NC)"

deploy: build ## Build images and deploy to minikube
	@echo "$(BLUE)Deploying to minikube...$(NC)"
	kubectl apply -f k8s/
	@echo "$(GREEN)✓ Deployment complete$(NC)"

tunnel: ## Start minikube tunnel (requires sudo)
	@echo "$(BLUE)Starting minikube tunnel...$(NC)"
	@echo "$(YELLOW)This requires sudo access and will run in foreground$(NC)"
	minikube tunnel

port-forward: ## Set up port forwarding for all services
	@echo "$(BLUE)Setting up port forwarding...$(NC)"
	@echo "$(YELLOW)Run these commands in separate terminals:$(NC)"
	@echo "  kubectl port-forward svc/fe-nextjs 3000:3000 -n ecommerce"
	@echo "  kubectl port-forward svc/be-api-gin 8080:8080 -n ecommerce"
	@echo "  kubectl port-forward svc/postgres 5433:5432 -n ecommerce"
	@echo "  kubectl port-forward svc/redis 6379:6379 -n ecommerce"

dashboard: ## Open Kubernetes dashboard
	@echo "$(BLUE)Opening Kubernetes dashboard...$(NC)"
	minikube dashboard

skaffold-dev: ## Run with Skaffold (hot reload)
	@if ! command -v skaffold >/dev/null 2>&1; then \
		echo "$(YELLOW)✗ Skaffold is not installed$(NC)"; \
		echo "$(BLUE)Install with: brew install skaffold$(NC)"; \
		echo "$(BLUE)Or run: make install-tools$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Starting Skaffold dev mode...$(NC)"
	skaffold dev

tilt-up: ## Run with Tilt (hot reload with UI)
	@if ! command -v tilt >/dev/null 2>&1; then \
		echo "$(YELLOW)✗ Tilt is not installed$(NC)"; \
		echo "$(BLUE)Install with: brew install tilt$(NC)"; \
		echo "$(BLUE)Or run: make install-tools$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Starting Tilt...$(NC)"
	tilt up

context: ## Show current Kubernetes context
	@echo "$(BLUE)Current context:$(NC)"
	@kubectl config current-context
