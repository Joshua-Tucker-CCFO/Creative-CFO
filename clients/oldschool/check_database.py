#!/usr/bin/env python3
import pyodbc
import os

# Connection details
server = 'oldschoolbi.database.windows.net'
database = 'OldSchool-Dev-DB'
username = 'CloudSA251754e9@oldschoolbi'
password = '*"P{"p50WN4l$A;1qAZZ'

# Connection string
conn_str = f'DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={server};DATABASE={database};UID={username};PWD={password};Encrypt=yes;TrustServerCertificate=yes'

try:
    # Connect to database
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    
    # Get schemas
    print("=== SCHEMAS IN DATABASE ===")
    cursor.execute("""
        SELECT DISTINCT TABLE_SCHEMA, COUNT(*) as table_count
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA NOT IN ('dbo', 'guest', 'INFORMATION_SCHEMA', 'sys')
        GROUP BY TABLE_SCHEMA
        ORDER BY TABLE_SCHEMA
    """)
    
    schemas = cursor.fetchall()
    for schema, count in schemas:
        print(f"{schema}: {count} tables")
    
    # Get sample tables from key schemas
    print("\n=== KEY TABLES ===")
    cursor.execute("""
        SELECT TABLE_SCHEMA, TABLE_NAME
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA IN ('cin7core', 'shopify_au')
        ORDER BY TABLE_SCHEMA, TABLE_NAME
    """)
    
    tables = cursor.fetchall()
    current_schema = None
    for schema, table in tables:
        if schema != current_schema:
            print(f"\n{schema}:")
            current_schema = schema
        print(f"  - {table}")
    
    conn.close()
    
except Exception as e:
    print(f"Error: {e}")