# E-Commerce Platform TODO

## GraphQL Migration Roadmap

### Phase 1: Initial GraphQL Setup ✅ In Progress
- [ ] Create `be-graphql-go` service with gqlgen
- [ ] Implement core queries:
  - [x] `getHomepage` - Featured products, categories, recommendations (PRIORITY)
  - [x] `getProductDetail(id)` - Product + inventory + similar items
- [ ] Implement core mutations:
  - [x] `createOrder` - Orchestrate inventory reservation + order creation
- [ ] Add GraphQL subscriptions support:
  - [ ] `orderStatusUpdated` - Real-time order status changes
  - [ ] `inventoryUpdated` - Real-time inventory updates
  - [ ] `newProductAdded` - Real-time new product notifications

### Phase 2: REST Endpoint Migration to GraphQL (Future)
The following REST endpoints should be migrated to GraphQL queries/mutations:

#### Product/Listing Operations
- [ ] `GET /api/products` → `query listProducts`
- [ ] `GET /api/products/:id` → Already covered by `getProductDetail`
- [ ] `POST /api/products` → `mutation createProduct`
- [ ] `PUT /api/products/:id` → `mutation updateProduct`
- [ ] `DELETE /api/products/:id` → `mutation deleteProduct`
- [ ] `PUT /api/products/:id/inventory` → `mutation updateInventory`

#### Order Operations
- [ ] `GET /api/orders` → `query listOrders`
- [ ] `GET /api/orders/:id` → `query getOrder`
- [ ] `POST /api/orders` → Already covered by `createOrder` mutation
- [ ] `PUT /api/orders/:id/status` → `mutation updateOrderStatus`
- [ ] `DELETE /api/orders/:id` → `mutation cancelOrder`

#### User Operations
- [ ] `GET /api/users/profile` → `query getUserProfile`
- [ ] `PUT /api/users/profile` → `mutation updateUserProfile`
- [ ] `POST /api/users/register` → `mutation registerUser`
- [ ] `POST /api/users/login` → `mutation loginUser` (or keep as REST for security)

#### Search & Discovery
- [ ] `GET /api/products/search` → `query searchProducts`
- [ ] `GET /api/products/featured` → Already covered by `getHomepage`
- [ ] `GET /api/products/recommended` → `query getRecommendations`
- [ ] `GET /api/categories` → `query listCategories`
- [ ] `GET /api/categories/:id` → `query getCategoryDetail`

### Phase 3: Performance Optimizations
- [ ] Implement DataLoader pattern for N+1 query optimization
  - [ ] Product batching
  - [ ] Inventory batching
  - [ ] User data batching
  - [ ] Category batching
- [ ] Add query complexity analysis
- [ ] Add query depth limiting
- [ ] Implement field-level caching with Redis
- [ ] Add APQ (Automatic Persisted Queries)

### Phase 4: Advanced Features
- [ ] Add GraphQL playground/explorer in development
- [ ] Implement federation if splitting GraphQL across services
- [ ] Add field-level authorization
- [ ] Implement rate limiting per resolver
- [ ] Add GraphQL metrics and monitoring
- [ ] Create GraphQL schema versioning strategy
- [ ] Add GraphQL query cost analysis
- [ ] Implement cursor-based pagination for all list queries

### Phase 5: Developer Experience
- [ ] Generate TypeScript types from GraphQL schema for frontend
- [ ] Add GraphQL code generation for Go backend
- [ ] Create GraphQL testing utilities
- [ ] Add GraphQL mock server for frontend development
- [ ] Document GraphQL best practices
- [ ] Create GraphQL query examples documentation

## Infrastructure Tasks
- [ ] Add `be-graphql-go` to Kubernetes deployments
- [ ] Configure service mesh for GraphQL service
- [ ] Set up GraphQL gateway monitoring
- [ ] Add GraphQL-specific logging and tracing
- [ ] Configure load balancing for GraphQL endpoint

## Frontend Tasks
- [ ] Set up Apollo Client or urql
- [ ] Migrate homepage to use GraphQL
- [ ] Migrate product detail page to use GraphQL
- [ ] Migrate checkout flow to use GraphQL
- [ ] Add GraphQL error handling
- [ ] Add GraphQL loading states
- [ ] Add GraphQL optimistic updates

## Documentation
- [ ] Document GraphQL schema design principles
- [ ] Create GraphQL API documentation
- [ ] Add examples for common queries
- [ ] Document REST to GraphQL migration guide
- [ ] Create troubleshooting guide

## Notes
- REST and GraphQL will coexist
- REST remains for simple CRUD operations
- GraphQL for complex data fetching and aggregations
- Mobile apps should prefer GraphQL for flexibility
- Internal services can continue using REST or gRPC directly
