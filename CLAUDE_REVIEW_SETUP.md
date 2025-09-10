# Claude Automated Code Review Setup

This repository includes automated Claude-powered code reviews for dbt projects.

## Setup Options

### Option 1: GitHub Actions (Recommended)
Automatically reviews all PRs with Claude feedback as comments.

**Setup:**
1. Add your Anthropic API key to GitHub Secrets:
   - Go to: `Settings` → `Secrets and variables` → `Actions`
   - Add secret: `ANTHROPIC_API_KEY` = `your-api-key`
2. The workflow will automatically run on PRs

### Option 2: Pre-commit Hooks (Local Development)
Reviews code before each commit locally.

**Setup:**
```bash
# Install pre-commit
pip install pre-commit

# Set API key in your shell profile (~/.zshrc or ~/.bash_profile)
export ANTHROPIC_API_KEY="your-api-key-here"

# Install hooks
cd /path/to/your/repo
pre-commit install

# Test the setup
pre-commit run --all-files
```

### Option 3: Manual Review Script
Run Claude reviews on-demand.

**Usage:**
```bash
# Set API key
export ANTHROPIC_API_KEY="your-api-key-here"

# Review specific files
python scripts/claude_review.py models/staging/stg_customers.sql

# Review all SQL files in a directory  
python scripts/claude_review.py models/staging/*.sql
```

## What Claude Reviews

### dbt SQL Models
- SQL syntax and dbt best practices
- Model materialization strategy
- Performance optimization opportunities  
- Data quality and testing suggestions
- Naming conventions and documentation
- Security considerations

### dbt YAML Files
- YAML syntax and structure
- dbt schema configurations
- Test coverage and quality
- Documentation completeness
- Source and model configurations

## Review Examples

### ✅ Good Code
```
🤖 Claude Review: models/staging/stg_customers.sql
============================================================
✅ Code looks good!

The model follows dbt best practices:
- Clean CTE structure
- Proper column naming  
- Good use of staging patterns
- Includes data type casting
============================================================
```

### ⚠️ Issues Found
```
🤖 Claude Review: models/marts/customer_analytics.sql
============================================================
✅ Good SQL structure and CTE organization

⚠️ Issues to address:
- Missing tests in schema.yml
- Consider adding indexes hint for large table
- Hard-coded date '2023-01-01' should be parameterized

💡 Optimization suggestions:
- Use incremental materialization for this large table
- Add partition by date for better performance

🔧 Specific improvements:
- Add `{{ var('start_date', '2023-01-01') }}` instead of hard-coded date
============================================================
```

## Configuration

The review focuses on:
- **Code Quality**: Syntax, conventions, best practices
- **Performance**: Materialization, indexing, query optimization
- **Data Quality**: Testing, validation, error handling
- **Security**: No secrets, proper access patterns
- **Documentation**: Model descriptions, column documentation

## Troubleshooting

**API Key Issues:**
- Ensure `ANTHROPIC_API_KEY` is set correctly
- Check API key permissions and usage limits

**Pre-commit Not Running:**
- Run `pre-commit install` in repository root
- Check `.pre-commit-config.yaml` syntax

**GitHub Actions Failing:**
- Verify `ANTHROPIC_API_KEY` secret is set
- Check workflow permissions in repository settings