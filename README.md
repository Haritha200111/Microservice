# My Microservices Repo

This repository contains multiple microservices in a monorepo setup:
- `catalog-service` (Go)
- `notification-service` (Node.js)

## CI/CD
- **Jenkins multibranch pipeline** detects which services changed and builds, tests, pushes, and deploys them.
- **Helm** used for Kubernetes deployments.
- **Docker** used for containerization.
