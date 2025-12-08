# Quick Start Guide

This guide will help you get started with Repo Alert in under 5 minutes.

## Prerequisites

- PowerShell 5.1 or higher (Windows PowerShell or PowerShell Core)
- A GitHub account with a Personal Access Token
- An email account with SMTP access (Gmail recommended)

## Setup Steps

### 1. Configure Environment Variables

Copy the example environment file:
```powershell
Copy-Item .env.example .env
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

### 2. Run the Script

```powershell
.\Check-PrAlerts.ps1
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
```powershell
.\Demo.ps1
```

### Automate with Task Scheduler (Windows)

1. Open Task Scheduler
2. Create a new task
3. Set trigger to run every hour
4. Set action:
   - Program: `powershell.exe`
   - Arguments: `-ExecutionPolicy Bypass -File "C:\path\to\repo_alert\Check-PrAlerts.ps1"`

### Automate with Cron (Linux/Mac with PowerShell Core)

Run every hour:
```bash
crontab -e
# Add: 0 * * * * cd /path/to/repo_alert && /usr/local/bin/pwsh -File Check-PrAlerts.ps1
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
