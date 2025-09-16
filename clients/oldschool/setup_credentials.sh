#!/bin/bash

# Azure SQL Database Credentials Setup Script
# ============================================
# This script helps you set up environment variables for dbt to connect to Azure SQL Database

echo "======================================"
echo "Azure SQL Database Credentials Setup"
echo "======================================"
echo ""
echo "This script will help you set up the credentials for connecting to:"
echo "  Server: oldschoolbi.database.windows.net"
echo "  Database: OldSchool-Dev-DB"
echo ""
echo "You'll need to provide:"
echo "  1. Username (e.g., CloudSA251754e9@oldschoolbi)"
echo "  2. Password"
echo ""
echo "To set up your credentials, run the following commands in your terminal:"
echo ""
echo "# Export environment variables (temporary - for this session only):"
echo "export DBT_SYNAPSE_USER='your_username@oldschoolbi'"
echo "export DBT_SYNAPSE_PASSWORD='your_password'"
echo ""
echo "# OR add to your shell profile for permanent setup:"
echo "echo \"export DBT_SYNAPSE_USER='your_username@oldschoolbi'\" >> ~/.zshrc"
echo "echo \"export DBT_SYNAPSE_PASSWORD='your_password'\" >> ~/.zshrc"
echo "source ~/.zshrc"
echo ""
echo "After setting the variables, test the connection with:"
echo "cd ~/fivetran_dbt_project"
echo "dbt debug --profiles-dir ~/.dbt"
echo ""
echo "======================================"