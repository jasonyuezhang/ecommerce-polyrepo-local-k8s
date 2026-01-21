# GraphQL Service Implementation Plan

## Overview
This document outlines the changes needed across all repositories to add a centralized GraphQL endpoint (`be-graphql-go`) with request orchestration capabilities.

## Architecture Decision
- **Service**: New `be-graphql-go` (Go + gqlgen + GraphQL subscriptions)
- **Communication**: Direct gRPC calls to backend services
- **Strategy**: Coexist with REST (not replacing)
- **Priority Queries**:
  1. `getHomepage` - Featured products + categories + recommendations
  2. `getProductDetail` - Product + inventory + similar items
  3. `createOrder` - Orchestrated order creation with inventory reservation

---

## Repository Changes

### 1. **NEW REPO: be-graphql-go**

Create new repository with the following structure:

```
be-graphql-go/
├── cmd/
│   └── server/
│       └── main.go                 # Entry point
├── internal/
│   ├── config/
│   │   └── config.go              # Configuration
│   ├── graph/
│   │   ├── schema.graphqls        # GraphQL schema definition
│   │   ├── generated/             # gqlgen generated code
│   │   ├── model/                 # GraphQL models
│   │   ├── resolver.go            # Root resolver
│   │   └── resolvers/
│   │       ├── query.go           # Query resolvers
│   │       ├── mutation.go        # Mutation resolvers
│   │       └── subscription.go    # Subscription resolvers
│   ├── orchestrator/
│   │   ├── homepage.go            # Homepage data orchestration
│   │   ├── product.go             # Product detail orchestration
│   │   └── order.go               # Order creation orchestration
│   └── middleware/
│       ├── auth.go                # Authentication middleware
│       ├── cors.go                # CORS middleware
│       └── logging.go             # Logging middleware
├── pkg/
│   ├── grpc/
│   │   ├── clients.go             # gRPC client connections
│   │   ├── user_client.go         # User service client
│   │   ├── listing_client.go      # Listing service client
│   │   └── inventory_client.go    # Inventory service client
│   └── subscription/
│       └── manager.go             # WebSocket subscription manager
├── graph/
│   └── schema/
│       ├── homepage.graphqls      # Homepage schema
│       ├── product.graphqls       # Product schema
│       ├── order.graphqls         # Order schema
│       └── subscription.graphqls  # Subscription schema
├── scripts/
│   └── generate.sh                # Schema generation script
├── go.mod
├── go.sum
├── gqlgen.yml                     # gqlgen configuration
├── Dockerfile
├── Dockerfile.dev
├── .air.toml                      # Hot reload config
├── .env.example
└── README.md
```

#### Key Files:

**gqlgen.yml**:
```yaml
schema:
  - internal/graph/schema.graphqls
  - graph/schema/*.graphqls
exec:
  filename: internal/graph/generated/generated.go
model:
  filename: internal/graph/model/models_gen.go
resolver:
  filename: internal/graph/resolver.go
  type: Resolver
```

**GraphQL Schema (internal/graph/schema.graphqls)**:
```graphql
type Query {
  # Homepage aggregated data
  homepage: Homepage!

  # Product detail with inventory and recommendations
  productDetail(id: ID!): ProductDetail!
}

type Mutation {
  # Create order with inventory orchestration
  createOrder(input: CreateOrderInput!): OrderResult!
}

type Subscription {
  # Real-time order status updates
  orderStatusUpdated(userId: ID!): OrderStatusUpdate!

  # Real-time inventory updates
  inventoryUpdated(productId: ID!): InventoryUpdate!
}

type Homepage {
  featuredProducts: [Product!]!
  categories: [Category!]!
  recommendations: [Product!]!
  banners: [Banner!]!
}

type ProductDetail {
  product: Product!
  inventory: Inventory!
  similarProducts: [Product!]!
  reviews: ReviewSummary!
}
```

---

### 2. **proto-schemas** Repository

**Changes needed**:
- Add `graphql.proto` for GraphQL-specific message types (optional)
- Ensure existing protos support all fields needed by GraphQL queries

**New file**: `proto/graphql/v1/graphql.proto`
```protobuf
syntax = "proto3";

package graphql.v1;

// Aggregated homepage data
message HomepageData {
  repeated listing.v1.Listing featured_products = 1;
  repeated listing.v1.Category categories = 2;
  repeated listing.v1.Listing recommendations = 3;
}

// Product detail aggregation
message ProductDetailData {
  listing.v1.Listing product = 1;
  inventory.v1.InventoryStatus inventory = 2;
  repeated listing.v1.Listing similar_products = 3;
}
```

**Update Makefile** to include GraphQL proto generation:
```makefile
generate-graphql:
	buf generate --path proto/graphql
```

---

### 3. **local-k8s** Repository

**Changes needed**:

**a) Add GraphQL service deployment**:
`k8s/base/be-graphql-go/deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: be-graphql-go
  namespace: ecommerce
spec:
  replicas: 2
  selector:
    matchLabels:
      app: be-graphql-go
  template:
    metadata:
      labels:
        app: be-graphql-go
    spec:
      containers:
      - name: be-graphql-go
        image: ecommerce/be-graphql-go:latest
        ports:
        - containerPort: 8080  # GraphQL HTTP
          name: http
        - containerPort: 8081  # GraphQL WebSocket
          name: ws
        env:
        - name: PORT
          value: "8080"
        - name: WS_PORT
          value: "8081"
        - name: USER_SERVICE_ADDR
          value: "svc-user-django:50051"
        - name: LISTING_SERVICE_ADDR
          value: "svc-listing-spring:9090"
        - name: INVENTORY_SERVICE_ADDR
          value: "svc-inventory-rails:50052"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 3
```

**b) Add GraphQL service**:
`k8s/base/be-graphql-go/service.yaml`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: be-graphql-go
  namespace: ecommerce
spec:
  type: NodePort
  ports:
  - port: 8080
    targetPort: 8080
    nodePort: 30900
    name: http
  - port: 8081
    targetPort: 8081
    nodePort: 30901
    name: ws
  selector:
    app: be-graphql-go
```

**c) Update Skaffold config**:
`skaffold.yaml` - Add new build and deploy config:
```yaml
build:
  artifacts:
    # ... existing artifacts ...
    - image: ecommerce/be-graphql-go
      context: ../be-graphql-go
      docker:
        dockerfile: Dockerfile
deploy:
  kubectl:
    manifests:
      # ... existing manifests ...
      - k8s/base/be-graphql-go/*.yaml
```

**d) Update Makefile**:
Add GraphQL-specific targets:
```makefile
build-graphql: ## Build GraphQL service image only
	@echo "$(GREEN)Building be-graphql-go...$(NC)"
	cd ../be-graphql-go && docker build -t ecommerce/be-graphql-go:latest .

restart-graphql: ## Restart GraphQL service
	@echo "$(YELLOW)Restarting be-graphql-go...$(NC)"
	kubectl rollout restart deployment/be-graphql-go -n $(NAMESPACE)
	kubectl rollout status deployment/be-graphql-go -n $(NAMESPACE)

logs-graphql: ## Show GraphQL service logs
	kubectl logs -n $(NAMESPACE) -l app=be-graphql-go --tail=100 -f

shell-graphql: ## Open shell in GraphQL container
	kubectl exec -it -n $(NAMESPACE) deployment/be-graphql-go -- /bin/sh
```

---

### 4. **fe-nextjs** Repository

**Changes needed**:

**a) Add GraphQL client dependencies**:
`package.json`:
```json
{
  "dependencies": {
    "@apollo/client": "^3.8.0",
    "graphql": "^16.8.0",
    "graphql-ws": "^5.14.0"
  }
}
```

**b) Create Apollo Client setup**:
`src/lib/apollo-client.ts`:
```typescript
import { ApolloClient, InMemoryCache, HttpLink, split } from '@apollo/client';
import { GraphQLWsLink } from '@apollo/client/link/subscriptions';
import { getMainDefinition } from '@apollo/client/utilities';
import { createClient } from 'graphql-ws';

const httpLink = new HttpLink({
  uri: process.env.NEXT_PUBLIC_GRAPHQL_URL || 'http://localhost:8080/graphql',
});

const wsLink = typeof window !== 'undefined' ? new GraphQLWsLink(
  createClient({
    url: process.env.NEXT_PUBLIC_GRAPHQL_WS_URL || 'ws://localhost:8081/graphql',
  })
) : null;

const splitLink = typeof window !== 'undefined' && wsLink
  ? split(
      ({ query }) => {
        const definition = getMainDefinition(query);
        return (
          definition.kind === 'OperationDefinition' &&
          definition.operation === 'subscription'
        );
      },
      wsLink,
      httpLink,
    )
  : httpLink;

export const apolloClient = new ApolloClient({
  link: splitLink,
  cache: new InMemoryCache(),
});
```

**c) Create GraphQL queries**:
`src/graphql/queries/homepage.ts`:
```typescript
import { gql } from '@apollo/client';

export const GET_HOMEPAGE = gql`
  query GetHomepage {
    homepage {
      featuredProducts {
        id
        title
        price {
          amount
          currency
        }
        images {
          url
          alt
        }
      }
      categories {
        id
        name
        slug
        image {
          url
        }
      }
      recommendations {
        id
        title
        price {
          amount
          currency
        }
      }
    }
  }
`;
```

**d) Update homepage component**:
`src/pages/index.tsx` - Use GraphQL instead of REST

**e) Add .env.example**:
```
NEXT_PUBLIC_GRAPHQL_URL=http://localhost:30900/graphql
NEXT_PUBLIC_GRAPHQL_WS_URL=ws://localhost:30901/graphql
```

---

### 5. **be-api-gin** Repository

**Changes needed** (minimal):

**a) Update README**:
Add note about GraphQL service coexistence:
```markdown
## GraphQL Service

For complex data aggregations and real-time features, use the GraphQL endpoint:
- HTTP: http://localhost:30900/graphql
- WebSocket: ws://localhost:30901/graphql

The REST API continues to serve simple CRUD operations.
```

**b) No code changes needed** - REST and GraphQL coexist independently

---

### 6. **infra-terraform-eks** Repository

**Changes needed** (for production deployment):

**a) Add GraphQL service resources**:
`modules/eks/graphql-service.tf`:
```hcl
resource "aws_ecs_service" "graphql" {
  name            = "be-graphql-go"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.graphql.arn
  desired_count   = 2

  load_balancer {
    target_group_arn = aws_lb_target_group.graphql.arn
    container_name   = "be-graphql-go"
    container_port   = 8080
  }
}
```

**b) Add ALB target groups for GraphQL**:
```hcl
resource "aws_lb_target_group" "graphql" {
  name     = "ecommerce-graphql"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}
```

---

### 7. **Parent Repository (ecommerce-polyrepo)**

**Changes needed**:

**a) Update .gitmodules**:
Add new submodule entry:
```ini
[submodule "be-graphql-go"]
	path = be-graphql-go
	url = https://github.com/jasonyuezhang/be-graphql-go.git
```

**b) Update Makefile**:
Add `be-graphql-go` to `SUBMODULES` variable:
```makefile
SUBMODULES := be-api-gin be-graphql-go fe-nextjs infra-terraform-eks local-k8s proto-schemas svc-inventory-rails svc-listing-spring svc-user-django
```

**c) Update README.md**:
Add GraphQL service to architecture section:
```markdown
### Services
- **be-api-gin**: Backend API Gateway built with Go and Gin framework
- **be-graphql-go**: GraphQL Gateway with request orchestration and subscriptions
- **svc-user-django**: User service built with Django
- **svc-inventory-rails**: Inventory service built with Ruby on Rails
- **svc-listing-spring**: Listing service built with Spring Boot
```

---

## Implementation Order

1. ✅ Create TODO.md and IMPLEMENTATION_PLAN.md in parent repo
2. Create `be-graphql-go` repository with basic structure
3. Update `proto-schemas` with GraphQL-specific protos
4. Update `local-k8s` with deployment configs
5. Update `fe-nextjs` with Apollo Client
6. Update `be-api-gin` README
7. Update `infra-terraform-eks` with production configs
8. Update parent repo with new submodule
9. Test end-to-end with `make git-workflow`

---

## Testing Plan

After implementation:
1. Start local K8s stack: `make start`
2. Verify GraphQL service is running: `curl http://localhost:30900/health`
3. Test homepage query via GraphQL Playground
4. Test product detail query
5. Test createOrder mutation
6. Test subscriptions via WebSocket
7. Verify frontend consumes GraphQL successfully

---

## Rollback Plan

If issues arise:
1. GraphQL service can be removed without affecting REST API
2. Frontend can fallback to REST endpoints
3. K8s deployment can be rolled back: `kubectl rollout undo deployment/be-graphql-go -n ecommerce`
