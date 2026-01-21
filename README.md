# E-Commerce Polyrepo - Local Kubernetes Setup

This directory contains Kubernetes configurations for running the e-commerce microservices on **Minikube**.

## 🚨 Important: Port Configuration

**This setup uses PostgreSQL port 5433** to avoid conflicts with the propel-gtm project which uses port 5432.

### Port Mappings

| Service | Host Port | Container Port | NodePort |
|---------|-----------|----------------|----------|
| PostgreSQL | 5433 | 5432 | 30543 |
| Redis | 6379 | 6379 | - |
| Frontend | 3000 | 3000 | 30300 |
| API Gateway | 8080 | 8080 | 30080 |
| User Service (REST) | 8001 | 8000 | 30801 |
| User Service (gRPC) | 50051 | 50051 | 30051 |
| Listing Service (REST) | 8082 | 8080 | 30802 |
| Listing Service (gRPC) | 9090 | 9090 | 30909 |
| Inventory Service (REST) | 3001 | 3000 | 30301 |
| Inventory Service (gRPC) | 50052 | 50051 | 30052 |

## Prerequisites

### Required Tools
1. **Minikube** - Local Kubernetes cluster
2. **kubectl** - Kubernetes CLI
3. **Docker** - Container runtime

### Optional Tools (for development)
4. **Skaffold** - Hot reload development
5. **Tilt** - UI-based development with hot reload

### Check Installed Tools

```bash
# Check what's installed
make check-tools
```

### Install Prerequisites

```bash
# See installation commands
make install-tools

# Or install directly (macOS with Homebrew):
brew install minikube kubectl docker

# Optional development tools
brew install skaffold tilt

# Start minikube
minikube start
```

## Quick Start

### Option 1: Using Makefile (Recommended)

#### Infrastructure Only (PostgreSQL + Redis)
If you haven't built the application Docker images yet, start with infrastructure only:

```bash
# Check for port conflicts
make port-check

# Start minikube and deploy only infrastructure (PostgreSQL, Redis)
make start-infra-only

# Check status
make status

# Stop services
make stop
```

#### Full Stack (All Services)
When you have all Docker images built:

```bash
# Check for port conflicts
make port-check

# Start minikube and deploy all services
make start

# Check status
make status

# View logs
make logs

# Stop services
make stop
```

### Option 2: Using kubectl Directly

```bash
# Apply all Kubernetes manifests
kubectl apply -f k8s/

# Check status
kubectl get pods -n ecommerce
kubectl get svc -n ecommerce

# Delete everything
kubectl delete namespace ecommerce
```

### Option 3: Using Skaffold (Hot Reload)

```bash
# Development mode with hot reload
skaffold dev

# Or use make command
make skaffold-dev
```

### Option 4: Using Tilt (Hot Reload + UI)

```bash
# Start Tilt with UI
tilt up

# Or use make command
make tilt-up

# Access Tilt UI at http://localhost:10350
```

### Option 5: Using Docker Compose

```bash
# For simpler local development without Kubernetes
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

## Accessing Services

### Via NodePort (Minikube IP)

```bash
# Get minikube IP
minikube ip

# Access services at:
# Frontend:    http://<minikube-ip>:30300
# API Gateway: http://<minikube-ip>:30080
# User Service: http://<minikube-ip>:30801
# Listing Service: http://<minikube-ip>:30802
# Inventory Service: http://<minikube-ip>:30301
```

### Via Port Forwarding (Localhost)

```bash
# Forward specific service
kubectl port-forward svc/fe-nextjs 3000:3000 -n ecommerce

# Or use make command to see all port-forward commands
make port-forward
```

### Via Minikube Tunnel (LoadBalancer)

```bash
# Start tunnel (requires sudo)
minikube tunnel

# Or use make command
make tunnel

# Services will be available at their service ports
```

## Building Images

```bash
# Build all Docker images in minikube's Docker daemon
make build

# Or manually
eval $(minikube docker-env)
docker build -t ecommerce-frontend:latest -f ../fe-nextjs/Dockerfile.dev ../fe-nextjs
# ... repeat for other services
```

## Database Access

### From Host Machine

```bash
# Using port-forward (recommended)
kubectl port-forward svc/postgres 5433:5432 -n ecommerce

# Connect with psql
PGPASSWORD=postgres psql -h localhost -p 5433 -U postgres -d users

# Or use NodePort
PGPASSWORD=postgres psql -h $(minikube ip) -p 30543 -U postgres -d users
```

### From Within Cluster

```bash
# Services use internal DNS
postgresql://postgres:postgres@postgres:5432/users
postgresql://postgres:postgres@postgres:5432/listings
postgresql://postgres:postgres@postgres:5432/inventory
postgresql://postgres:postgres@postgres:5432/ecommerce
```

## Debugging

### View Pod Logs

```bash
# List all pods
kubectl get pods -n ecommerce

# View logs
kubectl logs <pod-name> -n ecommerce

# Follow logs
kubectl logs -f <pod-name> -n ecommerce
```

### Execute Commands in Pods

```bash
# Get a shell in a pod
kubectl exec -it <pod-name> -n ecommerce -- /bin/sh

# Run a command
kubectl exec <pod-name> -n ecommerce -- env
```

### Check Service Status

```bash
# All resources
kubectl get all -n ecommerce

# Describe a pod
kubectl describe pod <pod-name> -n ecommerce

# Check events
kubectl get events -n ecommerce --sort-by='.lastTimestamp'
```

### Open Kubernetes Dashboard

```bash
# Open dashboard
make dashboard

# Or manually
minikube dashboard
```

## Common Issues

### Port 5432 Conflict

If you see "port 5432 already in use", it's likely the propel-gtm PostgreSQL is running:

```bash
# Check what's using port 5432
lsof -i :5432

# E-commerce uses port 5433 instead, so no conflict!
```

### Images Not Found (ImagePullBackOff)

If you see pods in `ImagePullBackOff` or `ErrImagePull` status, it means the Docker images haven't been built yet:

```bash
# Solution 1: Use infrastructure-only deployment
make start-infra-only  # Runs only PostgreSQL and Redis

# Solution 2: Build all images first, then deploy
eval $(minikube docker-env)
make build
make start
```

The infrastructure-only deployment (`k8s-infra/` directory) contains only PostgreSQL and Redis, which are available as public Docker images. The application services require building custom images from source code.

### Pods Stuck in Pending

Check if minikube has enough resources:

```bash
# Check resources
kubectl describe nodes

# Restart with more resources
minikube delete
minikube start --cpus=4 --memory=8192
```

### Connection Refused

Make sure all services are running:

```bash
# Check status
kubectl get pods -n ecommerce

# Wait for all pods to be Ready
kubectl wait --for=condition=ready pod --all -n ecommerce --timeout=300s
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                       Minikube Cluster                       │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Namespace: ecommerce                     │  │
│  │                                                       │  │
│  │  ┌─────────────┐  ┌──────────────┐  ┌─────────────┐│  │
│  │  │  Frontend   │  │  API Gateway │  │   User Svc  ││  │
│  │  │  (Next.js)  │→ │    (Gin)     │→ │  (Django)   ││  │
│  │  └─────────────┘  └──────────────┘  └─────────────┘│  │
│  │         ↓                ↓                  ↓        │  │
│  │  ┌─────────────┐  ┌──────────────┐  ┌─────────────┐│  │
│  │  │ Listing Svc │  │Inventory Svc │  │  PostgreSQL ││  │
│  │  │  (Spring)   │  │   (Rails)    │  │  (Port 5432)││  │
│  │  └─────────────┘  └──────────────┘  └─────────────┘│  │
│  │                                              ↓       │  │
│  │                                       ┌─────────────┐│  │
│  │                                       │    Redis    ││  │
│  │                                       └─────────────┘│  │
│  └──────────────────────────────────────────────────────┘  │
│                          ↕                                   │
│                   NodePort / Tunnel                         │
└─────────────────────────────────────────────────────────────┘
                          ↕
                   Host Machine
                PostgreSQL: 5433 (no conflict!)
```

## Cleanup

```bash
# Remove namespace only
make stop

# Stop minikube
make stop-minikube

# Complete cleanup (removes minikube)
make clean
```

## Development Workflow

### With Skaffold

```bash
# Start development mode
skaffold dev

# Skaffold will:
# 1. Build images
# 2. Deploy to Kubernetes
# 3. Stream logs
# 4. Auto-rebuild on code changes
```

### With Tilt

```bash
# Start Tilt
tilt up

# Tilt provides:
# 1. Web UI at http://localhost:10350
# 2. Live reload
# 3. Resource grouping
# 4. Log aggregation
```

### Manual Development

```bash
# 1. Make code changes
# 2. Rebuild image
eval $(minikube docker-env)
docker build -t ecommerce-frontend:latest -f ../fe-nextjs/Dockerfile.dev ../fe-nextjs

# 3. Restart deployment
kubectl rollout restart deployment/fe-nextjs -n ecommerce

# 4. Watch status
kubectl rollout status deployment/fe-nextjs -n ecommerce
```

## Running Alongside Propel-GTM

You can run both projects simultaneously:

```bash
# Terminal 1: Start propel-gtm (uses port 5432)
cd /Volumes/dock/src/propel/propel-gtm
docker-compose up

# Terminal 2: Start e-commerce (uses port 5433)
cd /Volumes/dock/src/ecommerce-polyrepo/local-k8s
make start

# No port conflicts! ✅
```

## Production Deployment

For production deployment to AWS EKS, see:
- `/infra-terraform-eks/` - Terraform configuration
- Update image tags to use container registry
- Configure proper secrets management
- Set up ingress controllers
- Enable monitoring and logging

## Support

For help with commands:

```bash
make help
```

For Kubernetes help:

```bash
kubectl --help
minikube --help
```
