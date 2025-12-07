#!/usr/bin/env python3
"""
Test script for check_pr_alerts.py
Tests the core functionality without requiring actual credentials.
"""

import sys
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime


def test_load_configuration():
    """Test configuration loading."""
    print("Testing configuration loading...")
    
    # Import after mocking to avoid import-time issues
    with patch('check_pr_alerts.load_dotenv'):
        with patch('check_pr_alerts.os.getenv') as mock_getenv:
            mock_getenv.side_effect = lambda key, default=None: {
                'GITHUB_TOKEN': 'test_token',
                'GITHUB_USERNAME': 'testuser',
                'SMTP_SERVER': 'smtp.test.com',
                'SMTP_PORT': '587',
                'SMTP_USERNAME': 'test@test.com',
                'SMTP_PASSWORD': 'test_pass',
                'EMAIL_FROM': 'from@test.com',
                'EMAIL_TO': 'to@test.com',
                'REPO_FILTER': '',
            }.get(key, default)
            
            from check_pr_alerts import load_configuration
            config = load_configuration()
            
            assert config['github_token'] == 'test_token'
            assert config['github_username'] == 'testuser'
            assert config['smtp_port'] == 587
            print("✓ Configuration loading works correctly")


def test_format_email_body():
    """Test email body formatting."""
    print("Testing email body formatting...")
    
    from check_pr_alerts import format_email_body
    
    # Test with no PRs
    html = format_email_body([], "testuser")
    assert "no pull requests assigned" in html.lower()
    print("✓ Empty PR list formatting works")
    
    # Test with PRs
    mock_prs = [
        {
            'title': 'Test PR',
            'url': 'https://github.com/test/repo/pull/1',
            'repository': 'test/repo',
            'number': 1,
            'created_at': datetime(2025, 1, 1, 12, 0, 0),
            'updated_at': datetime(2025, 1, 2, 12, 0, 0),
            'author': 'author1',
            'labels': ['bug', 'enhancement'],
        }
    ]
    
    html = format_email_body(mock_prs, "testuser")
    assert "Test PR" in html
    assert "test/repo" in html
    assert "#1" in html
    assert "author1" in html
    assert "bug" in html
    print("✓ PR list formatting works correctly")


def test_get_assigned_pull_requests():
    """Test fetching assigned pull requests."""
    print("Testing PR fetching...")
    
    from check_pr_alerts import get_assigned_pull_requests
    
    # Mock GitHub client
    mock_github = Mock()
    mock_user = Mock()
    mock_github.get_user.return_value = mock_user
    
    # Mock search results
    mock_issue = Mock()
    mock_issue.title = "Test PR"
    mock_issue.html_url = "https://github.com/test/repo/pull/1"
    mock_issue.number = 1
    mock_issue.created_at = datetime(2025, 1, 1)
    mock_issue.updated_at = datetime(2025, 1, 2)
    mock_issue.user.login = "author1"
    mock_issue.labels = []
    mock_issue.repository.full_name = "test/repo"
    
    mock_github.search_issues.return_value = [mock_issue]
    
    prs = get_assigned_pull_requests(mock_github, "testuser")
    
    assert len(prs) == 1
    assert prs[0]['title'] == "Test PR"
    assert prs[0]['repository'] == "test/repo"
    print("✓ PR fetching works correctly")


def test_missing_configuration():
    """Test that missing configuration is caught."""
    print("Testing missing configuration handling...")
    
    with patch('check_pr_alerts.load_dotenv'):
        with patch('check_pr_alerts.os.getenv') as mock_getenv:
            mock_getenv.return_value = None
            
            from check_pr_alerts import load_configuration
            
            try:
                load_configuration()
                assert False, "Should have raised ValueError"
            except ValueError as e:
                assert "Missing required configuration" in str(e)
                print("✓ Missing configuration is properly detected")


def main():
    """Run all tests."""
    print("=" * 60)
    print("Running tests for check_pr_alerts.py")
    print("=" * 60)
    print()
    
    try:
        test_load_configuration()
        test_format_email_body()
        test_get_assigned_pull_requests()
        test_missing_configuration()
        
        print()
        print("=" * 60)
        print("All tests passed! ✓")
        print("=" * 60)
        return 0
    
    except AssertionError as e:
        print(f"\n✗ Test failed: {e}")
        return 1
    except Exception as e:
        print(f"\n✗ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
