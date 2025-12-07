# Repo Alert

A Python tool that checks for GitHub pull requests assigned to you and sends email notifications.

## Features

- 🔍 Automatically checks for pull requests assigned to you across all repositories
- 📧 Sends email notifications with PR details
- 🎯 Optional repository filtering to focus on specific repos
- 🎨 Formatted HTML email with PR information including:
  - PR title, number, and link
  - Repository name
  - Author information
  - Created and updated timestamps
  - Labels

## Requirements

- Python 3.7 or higher
- GitHub Personal Access Token
- SMTP email account (e.g., Gmail)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/ccaabrw/repo_alert.git
cd repo_alert
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Configure environment variables:
```bash
cp .env.example .env
```

Edit the `.env` file with your actual credentials:

```env
# GitHub Configuration
GITHUB_TOKEN=your_github_personal_access_token
GITHUB_USERNAME=your_github_username

# Email Configuration (SMTP)
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your_email@gmail.com
SMTP_PASSWORD=your_email_password_or_app_password
EMAIL_FROM=your_email@gmail.com
EMAIL_TO=your_email@gmail.com

# Optional: Repository filter
REPO_FILTER=
```

### GitHub Token Setup

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token" (classic)
3. Give it a descriptive name (e.g., "Repo Alert")
4. Select the following scopes:
   - `repo` (Full control of private repositories)
   - `read:org` (Read org and team membership)
5. Generate and copy the token to your `.env` file

### Email Setup (Gmail Example)

For Gmail, you'll need to use an App Password:

1. Enable 2-Step Verification in your Google Account
2. Go to Google Account → Security → 2-Step Verification → App passwords
3. Generate a new app password for "Mail"
4. Use this password in the `SMTP_PASSWORD` field

## Usage

Run the script to check for assigned pull requests and send an email notification:

```bash
python check_pr_alerts.py
```

### Output Example

```
Loading configuration...
Connecting to GitHub...
Checking for pull requests assigned to @yourusername...
Found 2 assigned pull request(s)
Sending email notification...
Email notification sent successfully to your@email.com
Process completed successfully!

Summary of assigned pull requests:
  - owner/repository#123: Fix bug in authentication
  - owner/repository#124: Add new feature
```

## Automation

You can automate this script to run periodically using:

### Cron (Linux/Mac)

Add to your crontab to run every hour:
```bash
crontab -e
```

Add this line:
```
0 * * * * cd /path/to/repo_alert && /usr/bin/python3 check_pr_alerts.py >> /var/log/repo_alert.log 2>&1
```

### Task Scheduler (Windows)

1. Open Task Scheduler
2. Create a new task
3. Set trigger to run every hour
4. Set action to run `python check_pr_alerts.py` in the repository directory

### GitHub Actions

You can also run this as a GitHub Action. Create `.github/workflows/pr-alert.yml`:

```yaml
name: PR Alert
on:
  schedule:
    - cron: '0 * * * *'  # Run every hour
  workflow_dispatch:  # Allow manual trigger

jobs:
  check-prs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.9'
      - name: Install dependencies
        run: pip install -r requirements.txt
      - name: Check for assigned PRs
        env:
          GITHUB_TOKEN: ${{ secrets.GH_TOKEN }}
          GITHUB_USERNAME: ${{ secrets.GH_USERNAME }}
          SMTP_SERVER: ${{ secrets.SMTP_SERVER }}
          SMTP_PORT: ${{ secrets.SMTP_PORT }}
          SMTP_USERNAME: ${{ secrets.SMTP_USERNAME }}
          SMTP_PASSWORD: ${{ secrets.SMTP_PASSWORD }}
          EMAIL_FROM: ${{ secrets.EMAIL_FROM }}
          EMAIL_TO: ${{ secrets.EMAIL_TO }}
        run: python check_pr_alerts.py
```

Don't forget to add the secrets in your repository settings!

## Configuration Options

### Repository Filter

To only check specific repositories, set the `REPO_FILTER` environment variable with a comma-separated list of repository names:

```env
REPO_FILTER=repo1,repo2,important-project
```

This will only send notifications for PRs in repositories whose names contain any of the specified filters.

## Troubleshooting

### "Missing required configuration" error
- Make sure all required fields in `.env` are filled out
- Check that the `.env` file is in the same directory as the script

### "Authentication failed" (GitHub)
- Verify your GitHub token is correct and has the required scopes
- Check that the token hasn't expired

### "Authentication failed" (Email)
- For Gmail, ensure you're using an App Password, not your regular password
- Verify 2-Step Verification is enabled on your Google Account
- Check that SMTP settings are correct for your email provider

### No email received
- Check your spam/junk folder
- Verify the `EMAIL_TO` address is correct
- Test your SMTP credentials with a simple email client

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - feel free to use this tool for your own purposes.