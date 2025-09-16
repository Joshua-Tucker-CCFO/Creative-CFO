# dbt Clients Monorepo

**Scalable Analytics Platform for Multiple Clients**

A centralized dbt repository that enables rapid deployment of analytics solutions across multiple clients with 95% code reuse and 5-minute onboarding.

## 🏗️ Architecture

```
dbt-clients-monorepo/
├── shared/                    # 🔄 REUSABLE COMPONENTS
│   ├── macros/               # SQL functions used by all clients
│   └── scripts/              # Utility scripts and tools
│
├── clients/                  # 👥 CLIENT PROJECTS
│   ├── oldschool/           # OldSchool BI (Active)
│   └── packleader/          # PackLeader (Setup phase)
│
├── template/                # 📋 NEW CLIENT TEMPLATE
│   ├── dbt_project.yml     # Pre-configured with shared macros
│   ├── profiles.yml        # Database connection template
│   └── models/             # Standard folder structure
│
├── docs/                    # 📚 DOCUMENTATION
└── scripts/                 # 🤖 AUTOMATION
```

## 🚀 Quick Start

### For New Client Onboarding:
```bash
# 1. Copy template
cp -r template/ clients/new_client/

# 2. Update configuration
cd clients/new_client/
# Edit dbt_project.yml - set name and database
# Edit profiles.yml - set connection details

# 3. Deploy
dbt run --target dev
```

### For Existing Clients:
```bash
# Work on specific client
cd clients/oldschool/
dbt run --target prod
```

## 🎯 Key Features

### ✅ **95% Code Reuse**
- Shared macros for common transformations
- Standardized 5-layer architecture
- Universal business logic

### ✅ **5-Minute Onboarding**
- Pre-built templates
- Automated setup scripts
- Standard configurations

### ✅ **Client Isolation**
- Separate databases
- Independent deployments
- Custom business rules

### ✅ **Proven Architecture**
Each client follows the same pattern:
1. **Extract Layer** - Stored procedures
2. **Staging Layer** - Data cleaning
3. **Intermediate Layer** - Business logic
4. **Marts Layer** - Analytics tables
5. **Reporting Layer** - Power BI views

## 📊 Current Status

| Client | Database | Models | Status |
|--------|----------|--------|--------|
| **OldSchool** | OldSchool-Dev-DB | 35+ models | ✅ Active |
| **PackLeader** | TBD | Template | 🚧 Setup |

## 📚 Documentation

- [**Architecture Guide**](ARCHITECTURE.md) - Detailed structure explanation
- [**Project Breakdown**](docs/PROJECT_ARCHITECTURE_BREAKDOWN.md) - How everything works
- [**Onboarding Guide**](docs/new_client_onboarding_guide.md) - Step-by-step client setup
- [**Power BI Setup**](docs/powerbi_setup.md) - BI tool integration

## 🔧 Development

### Local Setup:
```bash
# Install dependencies
cd clients/your_client/
dbt deps

# Run models
dbt run --target dev

# Generate documentation
dbt docs generate && dbt docs serve
```

### CI/CD:
- Automated testing on PR
- Client-specific deployment
- Shared resource updates

## 💡 Business Value

**Traditional Approach**: 2-4 weeks per client
**Our Approach**: 5 minutes to 2 hours per client

**Scaling Factor**: Serve 100 clients with effort of 5

## 🤝 Contributing

1. Make changes to shared resources in `/shared/`
2. Test with existing clients
3. Update template if needed
4. Deploy to specific clients

---

**Built for scale. Optimized for speed. Designed for reuse.**