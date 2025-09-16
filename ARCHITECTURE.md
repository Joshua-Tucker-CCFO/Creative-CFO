# dbt Clients Monorepo Architecture

## Repository Structure

```
dbt-clients-monorepo/
├── shared/                     # SHARED RESOURCES (All clients use these)
│   └── macros/                 # Reusable SQL functions
│       ├── check_columns.sql
│       ├── check_tables.sql
│       ├── create_clean_tables.sql
│       └── ...
│
├── clients/                    # CLIENT-SPECIFIC PROJECTS
│   ├── oldschool/             # OldSchool BI client (formerly fivetran)
│   │   ├── dbt_project.yml   # References shared macros
│   │   ├── profiles.yml      # Database connection
│   │   ├── models/            # Client-specific models
│   │   │   ├── staging/       # Raw data cleanup
│   │   │   ├── intermediate/  # Business logic
│   │   │   ├── marts/        # Final tables
│   │   │   └── reporting/    # Power BI views
│   │   └── sql/              # Stored procedures
│   │
│   └── packleader/           # PackLeader client (formerly packleder)
│       ├── dbt_project.yml
│       └── ...
│
├── template/                  # BASE TEMPLATE for new clients
│   └── dbt_project.yml
│
├── scripts/                   # Automation scripts
│   └── claude_review.py      # AI code review
│
└── .github/                  # CI/CD workflows
    └── workflows/
        └── dbt_ci.yml

```

## Key Design Principles

### 1. **Shared Macros**
- Located in `/shared/macros/`
- Available to ALL clients
- Write once, use everywhere
- Examples: date functions, data quality checks, transformations

### 2. **Client Isolation**
- Each client has complete dbt project
- Independent database connections
- Custom business logic
- No cross-client data access

### 3. **5-Layer Data Architecture**
Each client project follows this pattern:

1. **Extract Layer** (`sql/extract/`)
   - Stored procedures pull from raw Fivetran tables
   - Runs before dbt

2. **Staging Layer** (`models/staging/`)
   - Clean and standardize raw data
   - Materialized as views

3. **Intermediate Layer** (`models/intermediate/`)
   - Business logic and joins
   - Unify data across sources

4. **Marts Layer** (`models/marts/`)
   - Final business models
   - Materialized as tables

5. **Reporting Layer** (`models/reporting/`)
   - Power BI optimized views
   - Pre-calculated KPIs

## How to Use Shared Macros

In any client's `dbt_project.yml`:

```yaml
macro-paths: ["../../shared/macros", "macros"]
```

This allows the client to:
1. Use shared macros from `/shared/macros/`
2. Have client-specific macros in their own `macros/` folder

## Deployment

### Local Development
```bash
# For OldSchool client
cd clients/oldschool
dbt run --target dev

# For PackLeader client
cd clients/packleader
dbt run --target dev
```

### dbt Cloud Configuration
Set project subfolder per environment:
- OldSchool: `/clients/oldschool`
- PackLeader: `/clients/packleader`

### CI/CD
GitHub Actions can deploy based on which client folder changed:
```yaml
on:
  push:
    paths:
      - 'clients/oldschool/**'  # Triggers for OldSchool changes
      - 'clients/packleader/**' # Triggers for PackLeader changes
```

## Adding a New Client

1. **Copy template**:
   ```bash
   cp -r template/ clients/new_client/
   ```

2. **Update configuration**:
   - Edit `dbt_project.yml` - set name and profile
   - Edit `profiles.yml` - set database connection
   - Ensure `macro-paths` includes shared macros

3. **Add models**:
   - Create staging, intermediate, marts layers
   - Use shared macros for common logic

4. **Deploy**:
   ```bash
   cd clients/new_client
   dbt run
   ```

## Benefits of This Structure

✅ **Code Reuse**: Shared macros available to all clients
✅ **Client Isolation**: Each client's data is separate
✅ **Easy Onboarding**: Copy template, configure, deploy
✅ **Maintainability**: Fix bugs in shared code once
✅ **Scalability**: Add clients without affecting others
✅ **CI/CD Ready**: Deploy per client automatically

## Client Status

| Client | Database | Status | Models |
|--------|----------|--------|--------|
| OldSchool | OldSchool-Dev-DB | Active | 38 models |
| PackLeader | TBD | Setup Phase | Template |

## Next Steps

1. Ensure all generic macros are in `/shared/macros/`
2. Keep client-specific logic in client folders
3. Document shared macro usage
4. Set up CI/CD per client
5. Create onboarding automation script