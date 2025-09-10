#!/usr/bin/env python3
"""
Claude-powered code review script for dbt projects
"""

import os
import sys
import subprocess
from pathlib import Path
import anthropic

def get_file_content(file_path):
    """Read file content"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return f.read()
    except Exception as e:
        return f"Error reading file: {e}"

def get_git_diff(file_path):
    """Get git diff for file"""
    try:
        result = subprocess.run(
            ['git', 'diff', '--cached', file_path], 
            capture_output=True, 
            text=True
        )
        return result.stdout
    except Exception:
        return ""

def review_with_claude(file_path, content, diff=""):
    """Review file with Claude"""
    
    # Get API key from environment
    api_key = os.getenv('ANTHROPIC_API_KEY')
    if not api_key:
        print("⚠️  ANTHROPIC_API_KEY not set - skipping Claude review")
        return True
    
    client = anthropic.Anthropic(api_key=api_key)
    
    # Determine file type
    file_ext = Path(file_path).suffix.lower()
    
    if file_ext == '.sql':
        file_type = "dbt SQL model"
        review_focus = """
        1. SQL syntax and dbt best practices
        2. Model materialization strategy
        3. Performance optimization opportunities
        4. Data quality and testing suggestions
        5. Naming conventions and documentation
        6. Security considerations (no hardcoded values)
        """
    elif file_ext in ['.yml', '.yaml']:
        file_type = "dbt YAML configuration"
        review_focus = """
        1. YAML syntax and structure
        2. dbt schema configurations
        3. Test coverage and quality
        4. Documentation completeness
        5. Source and model configurations
        """
    else:
        return True  # Skip non-dbt files
    
    prompt = f"""
    Please review this {file_type} for a data engineering project using dbt and Azure Synapse.
    
    Focus on:
    {review_focus}
    
    File: {file_path}
    
    Content:
    ```
    {content}
    ```
    
    {f"Recent changes (git diff):\n```\n{diff}\n```" if diff else ""}
    
    Provide:
    - ✅ What looks good
    - ⚠️  Issues to address (if any)  
    - 💡 Optimization suggestions (if any)
    - 🔧 Specific code improvements (if needed)
    
    Keep feedback concise and actionable. If the code looks good, just say "✅ Code looks good!"
    """
    
    try:
        response = client.messages.create(
            model="claude-3-haiku-20240307",  # Fast model for code review
            max_tokens=1000,
            messages=[{"role": "user", "content": prompt}]
        )
        
        review = response.content[0].text
        
        print(f"\n🤖 Claude Review: {file_path}")
        print("=" * 60)
        print(review)
        print("=" * 60)
        
        # Check if there are critical issues (basic heuristic)
        critical_indicators = ['error', 'critical', 'security', 'dangerous', 'fix immediately']
        has_critical = any(indicator in review.lower() for indicator in critical_indicators)
        
        if has_critical:
            print("\n❌ Critical issues found - please address before committing")
            return False
            
        return True
        
    except Exception as e:
        print(f"⚠️  Claude review failed for {file_path}: {e}")
        return True  # Don't block commits on API failures

def main():
    """Main review function"""
    files_to_review = sys.argv[1:] if len(sys.argv) > 1 else []
    
    if not files_to_review:
        print("No files specified for review")
        return 0
    
    all_passed = True
    
    for file_path in files_to_review:
        if not os.path.exists(file_path):
            continue
            
        content = get_file_content(file_path)
        diff = get_git_diff(file_path)
        
        passed = review_with_claude(file_path, content, diff)
        all_passed = all_passed and passed
    
    return 0 if all_passed else 1

if __name__ == "__main__":
    exit(main())