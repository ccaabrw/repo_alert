#!/usr/bin/env python3
"""
Example/Demo script showing how to use the repo_alert functionality programmatically.
This demonstrates the core functionality without requiring actual credentials.
"""

from datetime import datetime
from check_pr_alerts import format_email_body


def demo_email_formatting():
    """Demonstrate email formatting with sample data."""
    
    print("=" * 70)
    print("Repo Alert - Email Formatting Demo")
    print("=" * 70)
    print()
    
    # Sample PR data
    sample_prs = [
        {
            'title': 'Add user authentication feature',
            'url': 'https://github.com/example/repo1/pull/123',
            'repository': 'example/repo1',
            'number': 123,
            'created_at': datetime(2025, 12, 1, 10, 30, 0),
            'updated_at': datetime(2025, 12, 5, 14, 15, 0),
            'author': 'john_doe',
            'labels': ['enhancement', 'security'],
        },
        {
            'title': 'Fix bug in payment processing',
            'url': 'https://github.com/example/repo2/pull/456',
            'repository': 'example/repo2',
            'number': 456,
            'created_at': datetime(2025, 12, 3, 9, 0, 0),
            'updated_at': datetime(2025, 12, 6, 16, 45, 0),
            'author': 'jane_smith',
            'labels': ['bug', 'high-priority'],
        },
        {
            'title': 'Update documentation for API endpoints',
            'url': 'https://github.com/example/repo1/pull/789',
            'repository': 'example/repo1',
            'number': 789,
            'created_at': datetime(2025, 12, 4, 11, 20, 0),
            'updated_at': datetime(2025, 12, 7, 10, 30, 0),
            'author': 'doc_writer',
            'labels': ['documentation'],
        },
    ]
    
    print("Generating email for scenario: Multiple PRs assigned")
    print("-" * 70)
    
    html_body = format_email_body(sample_prs, "demo_user")
    
    # Save to file for viewing
    output_file = "/tmp/demo_email.html"
    with open(output_file, 'w') as f:
        f.write(html_body)
    
    print(f"Generated email with {len(sample_prs)} pull requests")
    print(f"Email HTML saved to: {output_file}")
    print()
    print("Summary of PRs in the email:")
    for pr in sample_prs:
        print(f"  • {pr['repository']}#{pr['number']}: {pr['title']}")
        print(f"    Author: {pr['author']} | Labels: {', '.join(pr['labels'])}")
    print()
    
    # Demo: No PRs
    print("-" * 70)
    print("Generating email for scenario: No PRs assigned")
    print("-" * 70)
    
    html_body_empty = format_email_body([], "demo_user")
    
    output_file_empty = "/tmp/demo_email_empty.html"
    with open(output_file_empty, 'w') as f:
        f.write(html_body_empty)
    
    print(f"Email HTML saved to: {output_file_empty}")
    print()
    
    print("=" * 70)
    print("Demo completed successfully!")
    print("=" * 70)
    print()
    print("To view the generated emails, open the HTML files in a web browser:")
    print(f"  - {output_file}")
    print(f"  - {output_file_empty}")
    print()


if __name__ == "__main__":
    demo_email_formatting()
