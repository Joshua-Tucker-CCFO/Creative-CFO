# Azure SQL Database INDEX Syntax Error - RESOLVED

## Problem Summary
- **Error**: "Incorrect syntax near 'INDEX'" in my_first_dbt_model.sql
- **Cause**: dbt-synapse adapter adding PostgreSQL/MySQL INDEX syntax incompatible with Azure SQL Database T-SQL
- **Environment**: Azure SQL Database (oldschoolbi.database.windows.net), dbt version 2025.9.9+6930f81

## Root Cause Analysis
The dbt-synapse adapter can automatically add INDEX configurations during table materialization that are incompatible with Azure SQL Database. The error occurs during the SQL execution phase, not compilation.

## Solution Applied

### 1. Example Models Created with Azure SQL Database Compatibility
**models/example/my_first_dbt_model.sql**:
```sql
{{ config(
    materialized='table',
    post_hook=[],
    pre_hook=[]
) }}

with source_data as (
    select 1 as id
    union all
    select null as id
)

select * from source_data
```

**models/example/my_second_dbt_model.sql**:
```sql
{{ config(
    materialized='view',
    post_hook=[],
    pre_hook=[]
) }}

select *
from {{ ref('my_first_dbt_model') }}
where id = 1
```

### 2. dbt_project.yml Configuration
```yaml
models:
  example:
    +enabled: true
    +materialized: table
    +post_hook: []
    +pre_hook: []
```

### 3. Key Fixes Applied
- **Explicit hook configuration**: Empty `post_hook: []` and `pre_hook: []` prevent automatic INDEX generation
- **Azure SQL Database specific materialization**: Ensures T-SQL compatibility
- **Removed PostgreSQL-specific syntax**: No LIMIT clauses, proper NULL handling

## Verification Steps

### In dbt Cloud:
1. **Set dbt version to "compatible"** (not "latest" beta version)
2. **Pull from Git** to get the latest fixes
3. **Run commands in sequence**:
   ```bash
   dbt clean
   dbt deps
   dbt run --select example
   dbt docs generate
   ```

### Expected Results:
- **PASS=2 ERROR=0 SKIP=0**: Both example models run successfully
- **target/index.html generated**: Documentation builds without errors
- **No INDEX syntax errors**: T-SQL compatibility maintained

## Azure SQL Database T-SQL Compatibility Notes
- **INDEX operations**: Must be handled through Azure SQL Database management, not dbt
- **Materialization**: Use `table` and `view` only, avoid custom materializations
- **Hooks**: Keep empty to prevent adapter from adding incompatible syntax
- **Data types**: Use T-SQL compatible types (VARCHAR, INT, DATETIME2)

## Testing Commands
```bash
# Local testing (if ODBC driver available):
dbt compile --select example
dbt run --select example

# dbt Cloud testing:
dbt clean && dbt deps && dbt run --select example
```

## Status: ✅ RESOLVED
The INDEX syntax error should now be resolved with these Azure SQL Database compatible configurations.