# dbt Clients Monorepo

Centralized dbt repository for all client projects with shared templates and standardized deployment.

## Structure

```
dbt-clients-monorepo/
├── template/           # Standardized dbt template
├── clients/
│   ├── fivetran/      # Fivetran client project
│   └── packleder/     # Packleder client project
├── shared/
│   ├── macros/        # Shared macros across all clients
│   └── packages/      # Common dbt packages
└── deploy/            # Deployment scripts and configurations
```

## Usage

### For New Clients:
1. Copy the `template/` directory to `clients/[client-name]/`
2. Customize the `dbt_project.yml` with client-specific settings
3. Update connection profiles
4. Add client-specific models

### For Deployment:
- Each client project can be deployed independently
- Shared resources are available in `shared/`
- Use deployment scripts in `deploy/`

## Benefits of Monorepo Approach:
- ✅ Single deployment pipeline
- ✅ Shared code reuse (macros, packages)
- ✅ Consistent versioning across clients
- ✅ Centralized governance and standards
- ✅ Better dependency management
