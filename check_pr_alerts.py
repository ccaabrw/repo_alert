#!/usr/bin/env python3
"""
Repo Alert - Check for pull requests assigned to you and send email notifications.
"""

import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime
from typing import List, Dict, Any
from dotenv import load_dotenv
from github import Github, GithubException


def load_configuration():
    """Load configuration from environment variables."""
    load_dotenv()
    
    config = {
        'github_token': os.getenv('GITHUB_TOKEN'),
        'github_username': os.getenv('GITHUB_USERNAME'),
        'smtp_server': os.getenv('SMTP_SERVER', 'smtp.gmail.com'),
        'smtp_port': int(os.getenv('SMTP_PORT', '587')),
        'smtp_username': os.getenv('SMTP_USERNAME'),
        'smtp_password': os.getenv('SMTP_PASSWORD'),
        'email_from': os.getenv('EMAIL_FROM'),
        'email_to': os.getenv('EMAIL_TO'),
        'repo_filter': os.getenv('REPO_FILTER', '').strip(),
    }
    
    # Validate required configuration
    required_fields = ['github_token', 'github_username', 'smtp_username', 
                      'smtp_password', 'email_from', 'email_to']
    missing_fields = [field for field in required_fields if not config.get(field)]
    
    if missing_fields:
        raise ValueError(f"Missing required configuration: {', '.join(missing_fields)}")
    
    return config


def get_assigned_pull_requests(github_client: Github, username: str, repo_filter: str = '') -> List[Dict[str, Any]]:
    """
    Fetch pull requests assigned to the specified user.
    
    Args:
        github_client: Authenticated GitHub client
        username: GitHub username to check assignments for
        repo_filter: Optional comma-separated list of repository names to filter
    
    Returns:
        List of dictionaries containing PR information
    """
    assigned_prs = []
    
    try:
        # Get the authenticated user
        user = github_client.get_user(username)
        
        # Parse repository filter if provided
        repo_list = [r.strip() for r in repo_filter.split(',') if r.strip()] if repo_filter else []
        
        # Search for pull requests assigned to the user
        # Using GitHub search API to find PRs assigned to the user
        query = f"type:pr state:open assignee:{username}"
        issues = github_client.search_issues(query=query, sort='updated', order='desc')
        
        for issue in issues:
            # Check if we should filter by repository
            if repo_list:
                repo_name = issue.repository.full_name
                if not any(filter_name in repo_name for filter_name in repo_list):
                    continue
            
            pr_info = {
                'title': issue.title,
                'url': issue.html_url,
                'repository': issue.repository.full_name,
                'number': issue.number,
                'created_at': issue.created_at,
                'updated_at': issue.updated_at,
                'author': issue.user.login,
                'labels': [label.name for label in issue.labels],
            }
            assigned_prs.append(pr_info)
    
    except GithubException as e:
        print(f"Error fetching pull requests: {e}")
        raise
    
    return assigned_prs


def format_email_body(pull_requests: List[Dict[str, Any]], username: str) -> str:
    """
    Format the email body with pull request information.
    
    Args:
        pull_requests: List of PR dictionaries
        username: GitHub username
    
    Returns:
        Formatted HTML email body
    """
    if not pull_requests:
        return f"""
        <html>
            <body>
                <h2>Pull Request Alert</h2>
                <p>Good news! You have no pull requests assigned to you at the moment.</p>
                <p>Checked on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}</p>
            </body>
        </html>
        """
    
    pr_list_html = ""
    for pr in pull_requests:
        labels_html = ", ".join([f"<span style='background-color: #e1e4e8; padding: 2px 6px; border-radius: 3px; font-size: 12px;'>{label}</span>" for label in pr['labels']]) if pr['labels'] else "None"
        
        pr_list_html += f"""
        <div style="border: 1px solid #e1e4e8; border-radius: 6px; padding: 15px; margin-bottom: 15px; background-color: #f6f8fa;">
            <h3 style="margin-top: 0;">
                <a href="{pr['url']}" style="color: #0366d6; text-decoration: none;">{pr['title']}</a>
            </h3>
            <p style="margin: 5px 0;">
                <strong>Repository:</strong> {pr['repository']}<br>
                <strong>PR Number:</strong> #{pr['number']}<br>
                <strong>Author:</strong> {pr['author']}<br>
                <strong>Created:</strong> {pr['created_at'].strftime('%Y-%m-%d %H:%M:%S')}<br>
                <strong>Last Updated:</strong> {pr['updated_at'].strftime('%Y-%m-%d %H:%M:%S')}<br>
                <strong>Labels:</strong> {labels_html}
            </p>
        </div>
        """
    
    html_body = f"""
    <html>
        <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif; line-height: 1.6; color: #24292e;">
            <h2 style="color: #24292e;">Pull Request Alert for @{username}</h2>
            <p>You have <strong>{len(pull_requests)}</strong> pull request(s) assigned to you:</p>
            {pr_list_html}
            <hr style="border: 0; border-top: 1px solid #e1e4e8; margin: 20px 0;">
            <p style="font-size: 12px; color: #586069;">
                This is an automated alert generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}
            </p>
        </body>
    </html>
    """
    
    return html_body


def send_email_notification(config: Dict[str, Any], subject: str, body: str):
    """
    Send an email notification.
    
    Args:
        config: Configuration dictionary with SMTP settings
        subject: Email subject
        body: HTML email body
    """
    try:
        # Create message
        message = MIMEMultipart('alternative')
        message['Subject'] = subject
        message['From'] = config['email_from']
        message['To'] = config['email_to']
        
        # Attach HTML body
        html_part = MIMEText(body, 'html')
        message.attach(html_part)
        
        # Connect to SMTP server and send email
        with smtplib.SMTP(config['smtp_server'], config['smtp_port']) as server:
            server.starttls()
            server.login(config['smtp_username'], config['smtp_password'])
            server.send_message(message)
        
        print(f"Email notification sent successfully to {config['email_to']}")
    
    except Exception as e:
        print(f"Error sending email: {e}")
        raise


def main():
    """Main function to check for assigned PRs and send notifications."""
    try:
        # Load configuration
        print("Loading configuration...")
        config = load_configuration()
        
        # Initialize GitHub client
        print("Connecting to GitHub...")
        github_client = Github(config['github_token'])
        
        # Get assigned pull requests
        print(f"Checking for pull requests assigned to @{config['github_username']}...")
        pull_requests = get_assigned_pull_requests(
            github_client, 
            config['github_username'],
            config['repo_filter']
        )
        
        print(f"Found {len(pull_requests)} assigned pull request(s)")
        
        # Format email
        email_body = format_email_body(pull_requests, config['github_username'])
        
        # Determine subject based on PR count
        if len(pull_requests) == 0:
            subject = "Pull Request Alert: No PRs assigned to you"
        elif len(pull_requests) == 1:
            subject = "Pull Request Alert: 1 PR assigned to you"
        else:
            subject = f"Pull Request Alert: {len(pull_requests)} PRs assigned to you"
        
        # Send email notification
        print("Sending email notification...")
        send_email_notification(config, subject, email_body)
        
        print("Process completed successfully!")
        
        # Print summary
        if pull_requests:
            print("\nSummary of assigned pull requests:")
            for pr in pull_requests:
                print(f"  - {pr['repository']}#{pr['number']}: {pr['title']}")
    
    except Exception as e:
        print(f"Error: {e}")
        raise


if __name__ == "__main__":
    main()
