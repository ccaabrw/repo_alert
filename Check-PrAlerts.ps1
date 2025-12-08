<#
.SYNOPSIS
    Repo Alert - Check for pull requests assigned to you and send email notifications.

.DESCRIPTION
    This script checks GitHub for pull requests assigned to a specific user and sends
    email notifications with PR details including title, repository, author, timestamps, and labels.

.PARAMETER ConfigFile
    Path to the .env configuration file. Defaults to .env in the script directory.

.EXAMPLE
    .\Check-PrAlerts.ps1
    Checks for assigned PRs using configuration from .env file and sends email notification.

.NOTES
    Requires PowerShell 5.1 or higher
    Uses GitHub REST API and SMTP for email notifications
#>

[CmdletBinding()]
param(
    [string]$ConfigFile = (Join-Path $PSScriptRoot ".env")
)

# Function to load configuration from .env file
function Get-Configuration {
    param([string]$EnvFilePath)
    
    if (-not (Test-Path $EnvFilePath)) {
        throw "Configuration file not found: $EnvFilePath"
    }
    
    Write-Host "Loading configuration..."
    
    $config = @{}
    Get-Content $EnvFilePath | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith('#')) {
            $parts = $line -split '=', 2
            if ($parts.Count -eq 2) {
                $key = $parts[0].Trim()
                $value = $parts[1].Trim()
                $config[$key] = $value
            }
        }
    }
    
    # Parse SMTP port with validation
    $smtpPortStr = if ($config['SMTP_PORT']) { $config['SMTP_PORT'] } else { '587' }
    try {
        $smtpPort = [int]$smtpPortStr
        if ($smtpPort -lt 1 -or $smtpPort -gt 65535) {
            throw "SMTP_PORT must be between 1 and 65535, got $smtpPort"
        }
    }
    catch {
        throw "Invalid SMTP_PORT value '$smtpPortStr': $_"
    }
    
    # Build validated configuration
    $validatedConfig = @{
        GitHubToken = $config['GITHUB_TOKEN']
        GitHubUsername = $config['GITHUB_USERNAME']
        SmtpServer = if ($config['SMTP_SERVER']) { $config['SMTP_SERVER'] } else { 'smtp.gmail.com' }
        SmtpPort = $smtpPort
        SmtpUsername = $config['SMTP_USERNAME']
        SmtpPassword = $config['SMTP_PASSWORD']
        EmailFrom = $config['EMAIL_FROM']
        EmailTo = $config['EMAIL_TO']
        RepoFilter = if ($config['REPO_FILTER']) { $config['REPO_FILTER'].Trim() } else { '' }
    }
    
    # Validate required fields
    $requiredFields = @('GitHubToken', 'GitHubUsername', 'SmtpUsername', 'SmtpPassword', 'EmailFrom', 'EmailTo')
    $missingFields = $requiredFields | Where-Object { -not $validatedConfig[$_] }
    
    if ($missingFields) {
        throw "Missing required configuration: $($missingFields -join ', ')"
    }
    
    return $validatedConfig
}

# Function to get assigned pull requests
function Get-AssignedPullRequests {
    param(
        [string]$GitHubToken,
        [string]$Username,
        [string]$RepoFilter = ''
    )
    
    $assignedPrs = @()
    
    try {
        # Parse repository filter if provided
        $repoList = if ($RepoFilter) { 
            $RepoFilter -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        } else { 
            @() 
        }
        
        # Search for pull requests assigned to the user using GitHub API
        $query = "type:pr state:open assignee:$Username"
        $uri = "https://api.github.com/search/issues?q=$([Uri]::EscapeDataString($query))&sort=updated&order=desc"
        
        $headers = @{
            'Authorization' = "Bearer $GitHubToken"
            'Accept' = 'application/vnd.github.v3+json'
            'User-Agent' = 'RepoAlert-PowerShell'
        }
        
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
        
        foreach ($issue in $response.items) {
            # Check if we should filter by repository
            if ($repoList.Count -gt 0) {
                $repoName = $issue.repository_url -replace '^.*/repos/', ''
                $matchFound = $false
                foreach ($filter in $repoList) {
                    if ($repoName -like "*$filter*") {
                        $matchFound = $true
                        break
                    }
                }
                if (-not $matchFound) {
                    continue
                }
            }
            
            $prInfo = [PSCustomObject]@{
                Title = $issue.title
                Url = $issue.html_url
                Repository = $issue.repository_url -replace '^.*/repos/', ''
                Number = $issue.number
                CreatedAt = [DateTime]::Parse($issue.created_at)
                UpdatedAt = [DateTime]::Parse($issue.updated_at)
                Author = $issue.user.login
                Labels = @($issue.labels | ForEach-Object { $_.name })
            }
            $assignedPrs += $prInfo
        }
    }
    catch {
        Write-Error "Error fetching pull requests: $_"
        throw
    }
    
    return $assignedPrs
}

# Function to format email body
function Format-EmailBody {
    param(
        [array]$PullRequests,
        [string]$Username
    )
    
    $currentTime = (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss UTC')
    
    if ($PullRequests.Count -eq 0) {
        return @"
<html>
    <body>
        <h2>Pull Request Alert</h2>
        <p>Good news! You have no pull requests assigned to you at the moment.</p>
        <p>Checked on: $currentTime</p>
    </body>
</html>
"@
    }
    
    $prListHtml = ""
    foreach ($pr in $PullRequests) {
        $labelsHtml = if ($pr.Labels.Count -gt 0) {
            ($pr.Labels | ForEach-Object {
                "<span style='background-color: #e1e4e8; padding: 2px 6px; border-radius: 3px; font-size: 12px;'>$_</span>"
            }) -join ", "
        } else {
            "None"
        }
        
        $createdStr = $pr.CreatedAt.ToString('yyyy-MM-dd HH:mm:ss')
        $updatedStr = $pr.UpdatedAt.ToString('yyyy-MM-dd HH:mm:ss')
        
        $prListHtml += @"

        <div style="border: 1px solid #e1e4e8; border-radius: 6px; padding: 15px; margin-bottom: 15px; background-color: #f6f8fa;">
            <h3 style="margin-top: 0;">
                <a href="$($pr.Url)" style="color: #0366d6; text-decoration: none;">$($pr.Title)</a>
            </h3>
            <p style="margin: 5px 0;">
                <strong>Repository:</strong> $($pr.Repository)<br>
                <strong>PR Number:</strong> #$($pr.Number)<br>
                <strong>Author:</strong> $($pr.Author)<br>
                <strong>Created:</strong> $createdStr<br>
                <strong>Last Updated:</strong> $updatedStr<br>
                <strong>Labels:</strong> $labelsHtml
            </p>
        </div>
"@
    }
    
    $htmlBody = @"
<html>
    <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif; line-height: 1.6; color: #24292e;">
        <h2 style="color: #24292e;">Pull Request Alert for @$Username</h2>
        <p>You have <strong>$($PullRequests.Count)</strong> pull request(s) assigned to you:</p>
        $prListHtml
        <hr style="border: 0; border-top: 1px solid #e1e4e8; margin: 20px 0;">
        <p style="font-size: 12px; color: #586069;">
            This is an automated alert generated on $currentTime
        </p>
    </body>
</html>
"@
    
    return $htmlBody
}

# Function to send email notification
function Send-EmailNotification {
    param(
        [hashtable]$Config,
        [string]$Subject,
        [string]$Body
    )
    
    try {
        $securePassword = ConvertTo-SecureString $Config.SmtpPassword -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential($Config.SmtpUsername, $securePassword)
        
        $mailParams = @{
            From = $Config.EmailFrom
            To = $Config.EmailTo
            Subject = $Subject
            Body = $Body
            BodyAsHtml = $true
            SmtpServer = $Config.SmtpServer
            Port = $Config.SmtpPort
            UseSsl = $true
            Credential = $credential
        }
        
        Send-MailMessage @mailParams
        
        Write-Host "Email notification sent successfully to $($Config.EmailTo)"
    }
    catch {
        Write-Error "Error sending email: $_"
        throw
    }
}

# Main execution
try {
    # Load configuration
    $config = Get-Configuration -EnvFilePath $ConfigFile
    
    # Initialize GitHub connection
    Write-Host "Connecting to GitHub..."
    
    # Get assigned pull requests
    Write-Host "Checking for pull requests assigned to @$($config.GitHubUsername)..."
    $pullRequests = Get-AssignedPullRequests `
        -GitHubToken $config.GitHubToken `
        -Username $config.GitHubUsername `
        -RepoFilter $config.RepoFilter
    
    Write-Host "Found $($pullRequests.Count) assigned pull request(s)"
    
    # Format email
    $emailBody = Format-EmailBody -PullRequests $pullRequests -Username $config.GitHubUsername
    
    # Determine subject based on PR count
    $subject = switch ($pullRequests.Count) {
        0 { "Pull Request Alert: No PRs assigned to you" }
        1 { "Pull Request Alert: 1 PR assigned to you" }
        default { "Pull Request Alert: $($pullRequests.Count) PRs assigned to you" }
    }
    
    # Send email notification
    Write-Host "Sending email notification..."
    Send-EmailNotification -Config $config -Subject $subject -Body $emailBody
    
    Write-Host "Process completed successfully!"
    
    # Print summary
    if ($pullRequests.Count -gt 0) {
        Write-Host "`nSummary of assigned pull requests:"
        foreach ($pr in $pullRequests) {
            Write-Host "  - $($pr.Repository)#$($pr.Number): $($pr.Title)"
        }
    }
}
catch {
    Write-Error "Error: $_"
    exit 1
}
