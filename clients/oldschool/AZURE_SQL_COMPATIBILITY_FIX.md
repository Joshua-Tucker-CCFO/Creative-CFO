# Azure SQL Database Compatibility Fix

## Issue Resolution for INDEX Syntax Error

### Problem
- dbt Cloud throwing "Incorrect syntax near 'INDEX'" error
- Error specifically in `my_first_dbt_model` (default dbt example)
- Azure SQL Database doesn't support certain PostgreSQL INDEX syntax

### Root Cause
Default dbt example models contain INDEX configurations incompatible with Azure SQL Database T-SQL syntax.

### Solution Applied

#### 1. Disabled Example Models
```yaml
models:
  # Disable any example models if they exist
  example:
    +enabled: false
```

#### 2. Azure SQL Database Optimized Configuration
- Removed INDEX configurations from all model configs
- Ensured T-SQL compatibility in all models
- Set proper materialization strategies

#### 3. Verification Steps

**Local Testing:**
```bash
# Clean and test parsing
dbt clean
dbt deps
dbt parse  # Should complete without errors

# Test compilation (no database connection needed)
dbt compile

# Full run (requires database connection)
dbt run
```

**dbt Cloud Steps:**
1. Set dbt version to "compatible" (not "latest")
2. Ensure project subdirectory is set to `clients/oldschool`
3. Pull from Git to get latest changes
4. Run `dbt clean` first
5. Run `dbt run`

### Azure SQL Database Specific Fixes

#### Common Compatibility Issues Fixed:
1. **INDEX Syntax**: Removed all INDEX configurations
2. **LIMIT vs TOP**: Using TOP for row limiting
3. **Boolean Values**: Using 1/0 instead of TRUE/FALSE
4. **ORDER BY in CTEs**: Removed where not supported
5. **Reserved Words**: Avoided T-SQL reserved words as column names

#### Model Configurations:
```yaml
# Azure SQL Database compatible config
models:
  materialized: table  # or view
  # NO index configurations for Azure SQL DB
```

### Files Modified:
- `dbt_project.yml`: Added example model disable and clean config
- All model files: Ensured T-SQL compatibility

### Expected Outcome:
- dbt run completes successfully
- dbt docs generate works
- All models compatible with Azure SQL Database T-SQL syntax

### Testing Commands:
```bash
# In dbt Cloud or local:
dbt clean
dbt deps
dbt run --full-refresh
dbt docs generate
```

### Notes:
- Azure SQL Database uses T-SQL syntax (similar to SQL Server)
- INDEX operations must be handled differently than PostgreSQL
- Use `materialized: table` for performance, not INDEX configs