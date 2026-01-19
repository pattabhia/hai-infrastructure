# HAI Intel Infrastructure

Complete infrastructure setup for HAI Intel platform.

## 📁 Directory Structure

```
10.HAIINTEL/infrastructure/
│
├── shared-infra/                    # Shared monitoring for ALL applications
│   ├── docker-compose.yml           # Prometheus + Grafana
│   ├── prometheus/                  # Prometheus config & alerts
│   ├── grafana/                     # Grafana dashboards
│   ├── Makefile                     # Commands for shared stack
│   └── README.md
│
├── keycloak-infra/                  # Keycloak authentication service
│   ├── docker-compose.yml           # Keycloak + PostgreSQL + PG-Exporter
│   ├── config/                      # Keycloak realm configurations
│   ├── keycloak/                    # Themes, providers
│   ├── postgres/                    # PostgreSQL init scripts
│   ├── terraform/                   # Azure infrastructure (AKS, etc.)
│   ├── kubernetes/                  # K8s manifests
│   ├── scripts/                     # Automation scripts
│   ├── docs/                        # Documentation
│   ├── Makefile                     # Commands for Keycloak stack
│   └── README.md
│
└── haiindexer-infra/                # Future: HAIIndexer service
    └── ...
```

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              10.HAIINTEL/infrastructure/                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │         shared-infra/ (Platform-wide)              │    │
│  ├────────────────────────────────────────────────────┤    │
│  │  - Prometheus (monitors ALL apps)                  │    │
│  │  - Grafana (dashboards for ALL apps)               │    │
│  │  - Future: Redis, RabbitMQ, API Gateway, etc.      │    │
│  └────────────────────────────────────────────────────┘    │
│                          ▲                                   │
│                          │ (scrapes metrics)                │
│         ┌────────────────┼────────────────┐                │
│         │                │                │                │
│  ┌──────▼──────────┐  ┌──▼────────────┐  ┌▼──────────┐   │
│  │ keycloak-infra/ │  │ haiindexer-   │  │ future-   │   │
│  │                 │  │ infra/        │  │ app-infra/│   │
│  ├─────────────────┤  ├───────────────┤  ├───────────┤   │
│  │ - Keycloak      │  │ - HAIIndexer  │  │ - App     │   │
│  │ - PostgreSQL    │  │ - PostgreSQL  │  │ - Services│   │
│  │ - PG-Exporter   │  │ - PG-Exporter │  │           │   │
│  │ - Terraform     │  │ - Terraform   │  │           │   │
│  │ - K8s manifests │  │ - K8s         │  │           │   │
│  └─────────────────┘  └───────────────┘  └───────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### 1. Start Shared Infrastructure (Required First)

```bash
cd shared-infra
make start
```

This starts:
- **Prometheus** at http://localhost:9090
- **Grafana** at http://localhost:3000 (admin/admin)

### 2. Start Keycloak Infrastructure

```bash
cd keycloak-infra
make start
```

This starts:
- **Keycloak** at http://localhost:8080 (admin/admin)
- **PostgreSQL** (Keycloak's database)
- **PostgreSQL Exporter** (sends metrics to Prometheus)

### 3. Verify Everything is Running

```bash
# Check shared infrastructure
cd shared-infra
make status

# Check Keycloak infrastructure
cd keycloak-infra
make status
```

## 📊 What Goes Where?

### **shared-infra/** - Platform-wide shared services

**Services:**
- Prometheus (monitors ALL apps)
- Grafana (dashboards for ALL apps)
- Future: Redis, RabbitMQ, API Gateway, etc.

**When to add here:**
- Services used by multiple applications
- Centralized monitoring/logging
- Shared caching/messaging
- API gateways

### **keycloak-infra/** - Keycloak-specific only

**Services:**
- Keycloak application
- Keycloak's dedicated PostgreSQL
- PostgreSQL Exporter (monitors Keycloak's DB only)

**Includes:**
- Terraform for Keycloak's Azure infrastructure
- Kubernetes manifests for Keycloak
- Keycloak-specific scripts and configs

### **haiindexer-infra/** - Future: HAIIndexer-specific

**Services:**
- HAIIndexer application
- HAIIndexer's dedicated PostgreSQL
- PostgreSQL Exporter (monitors HAIIndexer's DB only)

**Includes:**
- Terraform for HAIIndexer's infrastructure
- Kubernetes manifests for HAIIndexer
- HAIIndexer-specific scripts and configs

## 🔧 Common Commands

### Shared Infrastructure

```bash
cd shared-infra
make start          # Start Prometheus + Grafana
make stop           # Stop shared infrastructure
make logs           # View logs
make status         # Check status
make health         # Health check
```

### Keycloak Infrastructure

```bash
cd keycloak-infra
make start          # Start Keycloak stack
make stop           # Stop Keycloak stack
make logs           # View all logs
make logs-keycloak  # View Keycloak logs only
make status         # Check status
make health         # Health check
```

## 🌐 Network

All services use the shared network: **`haiintel-network`**

This allows:
- Keycloak to be monitored by Prometheus
- HAIIndexer (future) to be monitored by Prometheus
- Inter-service communication

## 📝 Key Concepts

### Database Per Application

Each application gets its own PostgreSQL instance:
- ✅ **Isolation** - Data separated
- ✅ **Performance** - No resource contention
- ✅ **Security** - Separate credentials
- ✅ **Scaling** - Scale independently
- ✅ **Monitoring** - Dedicated metrics

### PostgreSQL Exporter Per Database

Each PostgreSQL instance has its own exporter:
- `haiintel-keycloak-postgres-exporter` → monitors Keycloak's DB
- `haiintel-haiindexer-postgres-exporter` → monitors HAIIndexer's DB (future)

### Centralized Monitoring

One Prometheus + Grafana for all apps:
- ✅ Lower resource usage
- ✅ Unified monitoring view
- ✅ Easier to correlate issues
- ✅ Lower costs
- ✅ Simpler maintenance

## 🎯 Adding New Applications

When adding a new application (e.g., HAIIndexer):

1. **Create new infra folder**: `haiindexer-infra/`
2. **Add docker-compose.yml** with:
   - Application container
   - Dedicated PostgreSQL
   - PostgreSQL Exporter
3. **Update shared-infra/prometheus/prometheus.yml**:
   - Add scrape config for new app
   - Add scrape config for new PG exporter
4. **Create Grafana dashboards** in `shared-infra/grafana/dashboards/`
5. **Use same network**: `haiintel-network`

## 📚 Documentation

- **shared-infra/README.md** - Shared infrastructure details
- **keycloak-infra/README.md** - Keycloak infrastructure details
- **keycloak-infra/docs/** - Comprehensive Keycloak documentation

## 🔗 Service URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| Keycloak | http://localhost:8080 | admin / admin |
| Grafana | http://localhost:3000 | admin / admin |
| Prometheus | http://localhost:9090 | - |
| PostgreSQL | localhost:5432 | keycloak / keycloak_password |
| PG Exporter | http://localhost:9187/metrics | - |

## ✅ Next Steps

1. ✅ Start shared-infra
2. ✅ Start keycloak-infra
3. ✅ Access Keycloak and configure realms
4. ✅ View metrics in Grafana
5. 🔜 Deploy to Azure (see keycloak-infra/docs/DEPLOYMENT.md)

