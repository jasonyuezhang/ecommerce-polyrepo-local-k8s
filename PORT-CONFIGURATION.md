# Port Configuration - E-Commerce vs Propel-GTM

This document details all port configurations to ensure **zero conflicts** between the e-commerce polyrepo and propel-gtm projects.

## Port Conflict Analysis

### Propel-GTM Ports (from `/Volumes/dock/src/propel/propel-gtm/docker-compose.yml`)

| Service | Port(s) | Status |
|---------|---------|--------|
| PostgreSQL | 5432 | ⚠️ CONFLICT |
| API Server | 6060, 40000 | ✅ No conflict |
| App | 5001, 4000 | ✅ No conflict |
| Worker | 50000 | ✅ No conflict |
| Worker UI | 6062 | ✅ No conflict |

### E-Commerce Ports - UPDATED (Conflict-Free)

## Docker Compose Ports

| Service | Host Port | Container Port | Status |
|---------|-----------|----------------|--------|
| **PostgreSQL** | **5433** | 5432 | ✅ CHANGED to avoid conflict |
| Redis | 6379 | 6379 | ✅ No conflict |
| Frontend | 3000 | 3000 | ✅ No conflict |
| API Gateway | 8080 | 8080 | ✅ No conflict |
| User Service (REST) | 8001 | 8000 | ✅ No conflict |
| User Service (gRPC) | 50051 | 50051 | ✅ No conflict |
| Listing Service (REST) | 8082 | 8080 | ✅ No conflict |
| Listing Service (gRPC) | 9090 | 9090 | ✅ No conflict |
| Inventory Service (REST) | 3001 | 3000 | ✅ No conflict |
| Inventory Service (gRPC) | 50052 | 50051 | ✅ No conflict |

## Kubernetes (Minikube) NodePorts

| Service | NodePort | Internal Port | Status |
|---------|----------|---------------|--------|
| PostgreSQL | 30543 | 5432 | ✅ No conflict |
| Frontend | 30300 | 3000 | ✅ No conflict |
| API Gateway | 30080 | 8080 | ✅ No conflict |
| User Service (REST) | 30801 | 8000 | ✅ No conflict |
| User Service (gRPC) | 30051 | 50051 | ✅ No conflict |
| Listing Service (REST) | 30802 | 8080 | ✅ No conflict |
| Listing Service (gRPC) | 30909 | 9090 | ✅ No conflict |
| Inventory Service (REST) | 30301 | 3000 | ✅ No conflict |
| Inventory Service (gRPC) | 30052 | 50051 | ✅ No conflict |

## Connection Strings

### E-Commerce PostgreSQL

**From Host Machine (Docker Compose):**
```bash
postgresql://postgres:postgres@localhost:5433/users
postgresql://postgres:postgres@localhost:5433/listings
postgresql://postgres:postgres@localhost:5433/inventory
postgresql://postgres:postgres@localhost:5433/ecommerce
```

**From Host Machine (Minikube with port-forward):**
```bash
# After running: kubectl port-forward svc/postgres 5433:5432 -n ecommerce
postgresql://postgres:postgres@localhost:5433/users
```

**From Host Machine (Minikube NodePort):**
```bash
# Get minikube IP first: minikube ip
postgresql://postgres:postgres@$(minikube ip):30543/users
```

**From Within Docker Network:**
```bash
postgresql://postgres:postgres@postgres:5432/users
```

**From Within Kubernetes Cluster:**
```bash
postgresql://postgres:postgres@postgres:5432/users
```

### Propel-GTM PostgreSQL

**From Host Machine:**
```bash
postgresql://admin:test@localhost:5432/propeldb
```

## Files Updated with Port 5433

### 1. Docker Compose Configuration
**File:** `/Volumes/dock/src/ecommerce-polyrepo/local-k8s/docker-compose.yaml`
```yaml
postgres:
  ports:
    - "5433:5432"  # Changed from 5432:5432
```

### 2. Kubernetes PostgreSQL Service
**File:** `/Volumes/dock/src/ecommerce-polyrepo/local-k8s/k8s/02-postgres.yaml`
```yaml
spec:
  type: NodePort
  ports:
  - port: 5432
    targetPort: 5432
    nodePort: 30543  # Using 30543 to avoid port range conflicts
```

### 3. Skaffold Configuration
**File:** `/Volumes/dock/src/ecommerce-polyrepo/local-k8s/skaffold.yaml`
```yaml
portForward:
- resourceType: service
  resourceName: postgres
  namespace: ecommerce
  port: 5432
  localPort: 5433  # Port 5433 on host
```

### 4. Tiltfile Configuration
**File:** `/Volumes/dock/src/ecommerce-polyrepo/local-k8s/Tiltfile`
```python
k8s_resource('postgres',
  port_forwards='5433:5432',  # Using 5433 to avoid conflict
  labels=['infrastructure']
)
```

### 5. Architecture Diagram
**File:** `/Volumes/dock/src/ecommerce-polyrepo/architecture-diagram.md`
- Updated PostgreSQL port from 5432 to 5433 (Host:5433→5432)

### 6. Documentation
**File:** `/Volumes/dock/src/ecommerce-polyrepo/local-k8s/README.md`
- All port mappings updated
- Connection strings updated
- Port conflict resolution documented

## Verification Commands

### Check Port Conflicts

```bash
# Check if propel-gtm is using port 5432
lsof -i :5432

# Check if e-commerce can use port 5433
lsof -i :5433

# Should show no conflicts!
```

### Running Both Projects Simultaneously

```bash
# Terminal 1: Start propel-gtm
cd /Volumes/dock/src/propel/propel-gtm
docker-compose up

# Terminal 2: Start e-commerce (Docker Compose)
cd /Volumes/dock/src/ecommerce-polyrepo/local-k8s
docker-compose up

# OR Terminal 2: Start e-commerce (Minikube)
cd /Volumes/dock/src/ecommerce-polyrepo/local-k8s
make start
```

### Test Connections

```bash
# Connect to propel-gtm PostgreSQL (port 5432)
PGPASSWORD=test psql -h localhost -p 5432 -U admin -d propeldb

# Connect to e-commerce PostgreSQL (port 5433)
PGPASSWORD=postgres psql -h localhost -p 5433 -U postgres -d users

# Both should work without conflicts! ✅
```

## Port Allocation Strategy

### Reserved Port Ranges

**Propel-GTM:**
- 5432 (PostgreSQL)
- 6060-6062 (API, Worker UI)
- 4000-5001 (App)
- 40000, 50000 (API Server, Worker)

**E-Commerce:**
- 3000-3001 (Frontend, Inventory REST)
- 5433 (PostgreSQL - adjusted)
- 6379 (Redis)
- 8000-8082 (Services REST)
- 9090 (Listing gRPC)
- 50051-50052 (Services gRPC)

**Kubernetes NodePorts (30000-32767):**
- 30051-30052 (gRPC)
- 30080 (API Gateway)
- 30300-30301 (Frontend, Inventory)
- 30543 (PostgreSQL)
- 30801-30802 (User, Listing REST)
- 30909 (Listing gRPC)

## Summary

✅ **PostgreSQL port changed from 5432 to 5433**
✅ **All configuration files updated**
✅ **All documentation updated**
✅ **Both projects can run simultaneously**
✅ **Zero port conflicts**

## Quick Reference

### Start E-Commerce (Docker Compose)
```bash
cd /Volumes/dock/src/ecommerce-polyrepo/local-k8s
docker-compose up -d
```

### Start E-Commerce (Minikube)
```bash
cd /Volumes/dock/src/ecommerce-polyrepo/local-k8s
make start
```

### Access Services
- Frontend: http://localhost:3000
- API Gateway: http://localhost:8080
- PostgreSQL: localhost:5433
- User Service: http://localhost:8001
- Listing Service: http://localhost:8082
- Inventory Service: http://localhost:3001

### Stop Services
```bash
# Docker Compose
docker-compose down

# Minikube
make stop
```
