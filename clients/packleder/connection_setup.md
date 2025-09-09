# 🔌 Packleder Database Connection Setup

## Information Needed:

Please provide the following details for the Packleder database:

### 1. **Server Details**
- [ ] Server name: `_______________.database.windows.net`
- [ ] Database name: `_______________`
- [ ] Port: `1433` (default)

### 2. **Authentication**
- [ ] Username: `_______________`
- [ ] Password: `_______________`
- [ ] Authentication type: SQL Login

### 3. **Firewall Rules**
Need to add these IPs to Packleder's Azure SQL firewall:
- `34.233.79.135` (dbt Cloud connection test)
- `3.214.191.130` (dbt Cloud execution)
- `52.3.77.232` (dbt Cloud runner)
- Your local IP (for testing)

### 4. **Data Sources Available**
Check which schemas exist:
- [ ] Cin7 Core (schema name: _______)
- [ ] Shopify (schema name: _______)
- [ ] Xero (schema name: _______)
- [ ] Other: _______________

## Quick Test Commands:

Once you have the credentials, test with:

```bash
# Test connection
sqlcmd -S [SERVER].database.windows.net \
  -U [USERNAME] \
  -P '[PASSWORD]' \
  -d [DATABASE] \
  -Q "SELECT 'Connected!' as Status" \
  -C

# Check available schemas
sqlcmd -S [SERVER].database.windows.net \
  -U [USERNAME] \
  -P '[PASSWORD]' \
  -d [DATABASE] \
  -Q "SELECT DISTINCT TABLE_SCHEMA FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA NOT IN ('dbo', 'sys', 'INFORMATION_SCHEMA')" \
  -C

# Check Cin7 tables
sqlcmd -S [SERVER].database.windows.net \
  -U [USERNAME] \
  -P '[PASSWORD]' \
  -d [DATABASE] \
  -Q "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA LIKE '%cin7%'" \
  -C
```

## Environment Variables Setup:

```bash
# Add to ~/.zshrc or ~/.bashrc
export PACKLEDER_SERVER='[SERVER].database.windows.net'
export PACKLEDER_DATABASE='[DATABASE]'
export PACKLEDER_USER='[USERNAME]'
export PACKLEDER_PASSWORD='[PASSWORD]'
```

## dbt Profile Configuration:

Create `~/.dbt/profiles_packleder.yml`:

```yaml
packleder_azure:
  target: dev
  outputs:
    dev:
      type: synapse
      driver: 'ODBC Driver 18 for SQL Server'
      server: [SERVER].database.windows.net
      port: 1433
      database: [DATABASE]
      schema: dbt_dev
      authentication: sql
      user: [USERNAME]
      password: [PASSWORD]
      encrypt: true
      trust_cert: true
      threads: 4
```

---

**Please provide the connection details so we can:**
1. Connect to Packleder database
2. Analyze existing data structure
3. Apply the standardized template
4. Create matching Power BI models