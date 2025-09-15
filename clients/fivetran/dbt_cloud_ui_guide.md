# dbt Cloud UI Complete Guide

## Your Data Pipeline Architecture

```
APIs → Fivetran → Azure SQL → dbt Cloud → Analytics/BI Tools
                                   ↓
                            Automated deployment
                                   ↓
                            Multiple client DBs
```

## dbt Cloud UI Sections Explained

### 1. **Develop (IDE/Studio)**
**What it is:** Web-based code editor where you write SQL transformations

**Key Features:**
- **File Explorer (Left)**: Navigate your dbt project files
  - `models/` - Your SQL transformation files
  - `tests/` - Data quality tests
  - `macros/` - Reusable SQL functions
  - `analyses/` - Ad-hoc queries

- **Code Editor (Center)**: Write and edit SQL files
  ```sql
  -- Example: models/staging/stg_customers.sql
  SELECT
    customer_id,
    customer_name,
    created_at
  FROM {{ source('fivetran_schema', 'customers') }}
  ```

- **Command Line (Bottom)**: Run dbt commands
  ```bash
  dbt run --select stg_customers  # Run specific model
  dbt test                         # Run tests
  dbt compile                      # Check SQL syntax
  ```

- **Preview/Compile (Right)**: See compiled SQL before running

**When to use:**
- Creating new models
- Debugging transformations
- Testing changes before deploying

### 2. **Jobs**
**What it is:** Scheduled or triggered automation of your dbt runs

**Types of Jobs:**
1. **Production Jobs**: Run daily/hourly to refresh data
2. **CI Jobs**: Test pull requests before merging
3. **Ad-hoc Jobs**: Manual runs for specific needs

**Example Production Job:**
```
Schedule: 0 6 * * * (6 AM daily)
Commands:
  dbt source freshness  # Check if Fivetran synced
  dbt run               # Transform all data
  dbt test              # Validate data quality
  dbt snapshot          # Capture historical changes
```

### 3. **Environments**
**What it is:** Different configurations for dev/staging/prod

**Typical Setup:**
- **Development**: Your personal sandbox
- **CI**: For testing pull requests
- **Production**: Live data transformations

Each environment has:
- Different database credentials
- Different schemas (dev_yourname vs prod)
- Different compute resources

### 4. **Run History**
**What it is:** Log of all dbt executions

**Use for:**
- Debugging failures
- Performance monitoring
- Audit trail

### 5. **Documentation**
**What it is:** Auto-generated docs from your models

**Includes:**
- DAG (visual model dependencies)
- Column descriptions
- Tests results
- Data lineage

### 6. **Account Settings**
**What it is:** Project configuration and integrations

**Key areas:**
- API tokens
- Git connection
- Slack/email notifications
- User permissions

## How dbt Fits Into Your Process

### Phase 1: Initial Setup (One-time)
```
1. Fivetran syncs data from APIs to Azure SQL
   └─> Creates raw tables: cin7core.*, shopify.*, xero.*

2. In dbt Cloud IDE, create source definitions:
   └─> models/sources.yml defines where raw data lives

3. Build staging models:
   └─> Clean and standardize raw data

4. Build intermediate models:
   └─> Business logic and joins

5. Build marts:
   └─> Final tables for BI tools
```

### Phase 2: Daily Operations (Automated)
```
6 AM: Fivetran sync runs
  ↓
7 AM: dbt Cloud job triggers
  ↓
- Checks source freshness
- Runs transformations
- Tests data quality
- Updates documentation
  ↓
8 AM: Data ready in Power BI/Tableau
```

## Scaling for Multiple Clients

### Strategy 1: Single Project, Multiple Targets (Recommended)

**Project Structure:**
```
dbt-clients-monorepo/
├── clients/
│   ├── fivetran/           # Base template
│   │   ├── models/
│   │   └── dbt_project.yml
│   ├── client_a/           # Client A instance
│   └── client_b/           # Client B instance
```

**In dbt_project.yml:**
```yaml
vars:
  # Override per client
  client_name: "{{ env_var('DBT_CLIENT_NAME') }}"
  fivetran_database: "{{ env_var('DBT_DATABASE') }}"
  fivetran_schema: "{{ env_var('DBT_SCHEMA') }}"
```

**In profiles.yml:**
```yaml
fivetran_azure:
  outputs:
    client_a:
      database: ClientA-DB
      schema: dbt_client_a
    client_b:
      database: ClientB-DB
      schema: dbt_client_b
```

**Deploy command:**
```bash
# For Client A
dbt run --target client_a --vars '{"client_name": "client_a"}'

# For Client B
dbt run --target client_b --vars '{"client_name": "client_b"}'
```

### Strategy 2: Separate Projects (For different schemas)

**When clients have different source schemas:**

1. **Create Template Project:**
```bash
# Create base template
cp -r clients/fivetran clients/template

# For new client
cp -r clients/template clients/new_client
```

2. **Customize per Client:**
```yaml
# clients/new_client/sources.yml
sources:
  - name: new_client_fivetran
    tables:
      - name: custom_table  # Different from template
```

### Automation for New Clients

**1. Setup Script:**
```bash
#!/bin/bash
# setup_new_client.sh

CLIENT_NAME=$1
DATABASE_NAME=$2

# Copy template
cp -r clients/template clients/$CLIENT_NAME

# Update configuration
sed -i "s/TEMPLATE_DB/$DATABASE_NAME/g" clients/$CLIENT_NAME/dbt_project.yml

# Create dbt Cloud job
curl -X POST https://dh804.us1.dbt.com/api/v2/jobs/ \
  -H "Authorization: Token $DBT_CLOUD_TOKEN" \
  -d "{
    \"name\": \"$CLIENT_NAME Production\",
    \"project_id\": \"70471823470849\",
    \"environment_id\": \"prod_env_id\",
    \"execute_steps\": [\"dbt run\", \"dbt test\"],
    \"triggers\": {\"schedule\": \"0 6 * * *\"}
  }"
```

**2. Dynamic Schema Handling:**

```sql
-- models/staging/stg_dynamic_customers.sql
{{ config(
    pre_hook="EXEC sp_check_schema_compatibility '{{ var('client_name') }}'"
) }}

WITH source_data AS (
    SELECT * FROM {{ source(var('client_name') ~ '_fivetran', 'customers') }}
),

standardized AS (
    SELECT
        -- Handle schema differences
        {{ adapter.get_columns_in_relation(source_data) | map(attribute='name') | join(', ') }}
    FROM source_data
)

SELECT * FROM standardized
```

**3. Schema Discovery Macro:**
```sql
-- macros/discover_schema.sql
{% macro discover_client_schema(client_name) %}
  {% set query %}
    SELECT
      TABLE_NAME,
      COLUMN_NAME,
      DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = '{{ client_name }}_fivetran'
    ORDER BY TABLE_NAME, ORDINAL_POSITION
  {% endset %}

  {% set results = run_query(query) %}
  {% if execute %}
    {% for row in results %}
      {{ log(row[0] ~ '.' ~ row[1] ~ ': ' ~ row[2], info=true) }}
    {% endfor %}
  {% endif %}
{% endmacro %}
```

## Manual Intervention Points

### Where Manual Work is Needed:

1. **Initial Source Definition** (One-time per client)
   - Map Fivetran tables to dbt sources
   - Document any schema differences

2. **Business Logic Customization**
   - Client-specific calculations
   - Custom dimensions or metrics

3. **Test Thresholds**
   - Acceptable null rates
   - Data quality standards

### Where Automation Works:

1. **Standard Transformations**
   - Data type casting
   - Date formatting
   - Currency conversions

2. **Common Metrics**
   - Revenue calculations
   - Customer counts
   - Product analytics

3. **Deployment**
   - Job scheduling
   - Environment promotion
   - Documentation generation

## Practical Workflow for New Client

### Step 1: Analyze Client's Schema
```bash
# In dbt Cloud IDE
dbt run-operation discover_client_schema --args '{"client_name": "new_client"}'
```

### Step 2: Generate Source YAML
```python
# Python script to generate sources.yml
import pyodbc
import yaml

def generate_sources(client_name, connection_string):
    conn = pyodbc.connect(connection_string)
    cursor = conn.cursor()

    # Get all tables
    cursor.execute(f"""
        SELECT DISTINCT TABLE_NAME
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = '{client_name}_fivetran'
    """)

    tables = []
    for row in cursor:
        tables.append({
            'name': row[0],
            'description': f'Raw {row[0]} data from Fivetran'
        })

    sources = {
        'version': 2,
        'sources': [{
            'name': f'{client_name}_fivetran',
            'database': f'{client_name}-DB',
            'schema': f'{client_name}_fivetran',
            'tables': tables
        }]
    }

    with open(f'clients/{client_name}/models/sources.yml', 'w') as f:
        yaml.dump(sources, f)
```

### Step 3: Deploy via dbt Cloud API
```python
# deploy_client.py
import requests

def deploy_client(client_name, database_name):
    # Create environment
    env_response = requests.post(
        'https://dh804.us1.dbt.com/api/v2/environments/',
        headers={'Authorization': f'Token {DBT_CLOUD_TOKEN}'},
        json={
            'name': f'{client_name}_prod',
            'project_id': '70471823470849',
            'credentials': {
                'database': database_name,
                'schema': f'dbt_{client_name}'
            }
        }
    )

    # Create job
    job_response = requests.post(
        'https://dh804.us1.dbt.com/api/v2/jobs/',
        headers={'Authorization': f'Token {DBT_CLOUD_TOKEN}'},
        json={
            'name': f'{client_name} Daily Run',
            'environment_id': env_response.json()['id'],
            'execute_steps': ['dbt run', 'dbt test'],
            'schedule': '0 6 * * *'
        }
    )

    return job_response.json()['id']
```

## Best Practices for Multi-Client Setup

1. **Use Macros for Client-Specific Logic:**
```sql
-- macros/get_tax_rate.sql
{% macro get_tax_rate(client_name) %}
  {% if client_name == 'client_a' %}
    0.08
  {% elif client_name == 'client_b' %}
    0.10
  {% else %}
    0.0725  -- default
  {% endif %}
{% endmacro %}
```

2. **Parameterize Everything:**
```sql
-- models/marts/fct_sales.sql
SELECT
    *,
    amount * {{ get_tax_rate(var('client_name')) }} as tax_amount
FROM {{ ref('stg_sales') }}
WHERE date >= '{{ var("start_date", "2024-01-01") }}'
```

3. **Use Seeds for Client Config:**
```csv
-- data/client_config.csv
client_name,tax_rate,currency,timezone
client_a,0.08,USD,America/New_York
client_b,0.10,EUR,Europe/London
```

4. **Implement Feature Flags:**
```sql
-- models/marts/advanced_analytics.sql
{{ config(
    enabled=(var('client_name') in ['client_a', 'premium_clients'])
) }}
```

## Quick Reference Commands

```bash
# Test new client setup locally
dbt debug --target new_client

# Run only changed models
dbt run --select state:modified+

# Test specific client's models
dbt test --target client_a --select tag:client_specific

# Generate docs for client
dbt docs generate --target client_b

# Compare schemas between clients
dbt run-operation compare_client_schemas --args '{"client_a": "client_a", "client_b": "client_b"}'
```

## Summary

**dbt Cloud IDE** = Where you write SQL transformations
**Jobs** = Automated runs of your transformations
**Environments** = Different configs for dev/prod
**Run History** = Debugging and monitoring

**For new clients:**
1. Minimal manual work: Define sources, customize business logic
2. Mostly automated: Standard transforms, deployment, scheduling
3. Use variables and macros to minimize code duplication
4. One codebase can serve multiple clients with different targets