# Tiltfile for E-Commerce Polyrepo Development
# Uses port 5433 for PostgreSQL to avoid conflicts with propel-gtm (port 5432)

# Allow Tilt to use minikube
allow_k8s_contexts('minikube')

# Load Kubernetes manifests
k8s_yaml(kustomize('k8s'))

# Build and deploy services
docker_build('ecommerce-frontend',
  '../fe-nextjs',
  dockerfile='../fe-nextjs/Dockerfile.dev',
  live_update=[
    sync('../fe-nextjs', '/app'),
    run('cd /app && npm install', trigger=['package.json', 'package-lock.json'])
  ]
)

docker_build('ecommerce-api-gateway',
  '../be-api-gin',
  dockerfile='../be-api-gin/Dockerfile.dev',
  live_update=[
    sync('../be-api-gin', '/app'),
  ]
)

docker_build('ecommerce-user-service',
  '../svc-user-django',
  dockerfile='../svc-user-django/Dockerfile.dev',
  live_update=[
    sync('../svc-user-django', '/app'),
  ]
)

docker_build('ecommerce-listing-service',
  '../svc-listing-spring',
  dockerfile='../svc-listing-spring/Dockerfile.dev',
  live_update=[
    sync('../svc-listing-spring', '/app'),
  ]
)

docker_build('ecommerce-inventory-service',
  '../svc-inventory-rails',
  dockerfile='../svc-inventory-rails/Dockerfile.dev',
  live_update=[
    sync('../svc-inventory-rails', '/rails'),
  ]
)

# Define resources with port forwarding
k8s_resource('fe-nextjs',
  port_forwards='3000:3000',
  labels=['frontend']
)

k8s_resource('be-api-gin',
  port_forwards='8080:8080',
  labels=['gateway']
)

k8s_resource('svc-user-django',
  port_forwards=['8001:8000', '50051:50051'],
  labels=['services']
)

k8s_resource('svc-listing-spring',
  port_forwards=['8082:8080', '9090:9090'],
  labels=['services']
)

k8s_resource('svc-inventory-rails',
  port_forwards=['3001:3000', '50052:50051'],
  labels=['services']
)

k8s_resource('postgres',
  port_forwards='5433:5432',  # Using 5433 to avoid conflict with propel-gtm
  labels=['infrastructure']
)

k8s_resource('redis',
  port_forwards='6379:6379',
  labels=['infrastructure']
)
