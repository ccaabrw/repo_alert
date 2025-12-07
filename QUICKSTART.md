# Quick Start Guide

This guide will help you get started with Repo Alert in under 5 minutes.

## Prerequisites

- Python 3.7 or higher installed
- A GitHub account with a Personal Access Token
- An email account with SMTP access (Gmail recommended)

## Setup Steps

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Configure Environment Variables

Copy the example environment file:
```bash
cp .env.example .env
```

Edit the `.env` file with your credentials:
```env
GITHUB_TOKEN=ghp_your_token_here
GITHUB_USERNAME=your_username
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your.email@gmail.com
SMTP_PASSWORD=your_app_password
EMAIL_FROM=your.email@gmail.com
EMAIL_TO=your.email@gmail.com
```

#### Getting a GitHub Token

1. Go to https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Give it a name like "Repo Alert"
4. Select scopes: `repo`, `read:org`
5. Generate and copy the token

#### Setting up Gmail App Password

1. Enable 2-Step Verification: https://myaccount.google.com/security
2. Go to App passwords: https://myaccount.google.com/apppasswords
3. Select "Mail" and generate password
4. Use this password in SMTP_PASSWORD

### 3. Run the Script

```bash
python check_pr_alerts.py
```

You should see output like:
```
Loading configuration...
Connecting to GitHub...
Checking for pull requests assigned to @your_username...
Found 2 assigned pull request(s)
Sending email notification...
Email notification sent successfully to your@email.com
Process completed successfully!
```

## What's Next?

### Run Demo (Optional)

See example email output without needing credentials:
```bash
python demo.py
```

### Automate with Cron

Run every hour:
```bash
crontab -e
# Add: 0 * * * * cd /path/to/repo_alert && python3 check_pr_alerts.py
```

### Filter Specific Repositories

Add to your `.env`:
```env
REPO_FILTER=my-important-repo,another-repo
```

## Troubleshooting

**"Missing required configuration" error**
- Check all fields in `.env` are filled

**"Authentication failed" (GitHub)**
- Verify token is correct and has required scopes
- Check token hasn't expired

**"Authentication failed" (Email)**
- Use App Password for Gmail, not regular password
- Verify 2FA is enabled

**No email received**
- Check spam folder
- Verify EMAIL_TO address

## Support

For detailed documentation, see [README.md](README.md)
