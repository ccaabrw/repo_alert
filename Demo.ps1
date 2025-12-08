<#
.SYNOPSIS
    Example/Demo script showing how to use the repo_alert functionality programmatically.

.DESCRIPTION
    This demonstrates the core functionality without requiring actual credentials.
    Shows email formatting with sample data.

.EXAMPLE
    .\Demo.ps1
    Generates sample emails to demonstrate the formatting.

.NOTES
    Requires PowerShell 5.1 or higher
#>

[CmdletBinding()]
param()

# Function to format email body (copied from main script for demo purposes)
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

function Show-DemoEmailFormatting {
    <#
    .SYNOPSIS
        Demonstrate email formatting with sample data.
    #>
    
    Write-Host ("=" * 70)
    Write-Host "Repo Alert - Email Formatting Demo"
    Write-Host ("=" * 70)
    Write-Host ""
    
    # Sample PR data
    $samplePrs = @(
        [PSCustomObject]@{
            Title = 'Add user authentication feature'
            Url = 'https://github.com/example/repo1/pull/123'
            Repository = 'example/repo1'
            Number = 123
            CreatedAt = [DateTime]::Parse('2025-12-01 10:30:00')
            UpdatedAt = [DateTime]::Parse('2025-12-05 14:15:00')
            Author = 'john_doe'
            Labels = @('enhancement', 'security')
        },
        [PSCustomObject]@{
            Title = 'Fix bug in payment processing'
            Url = 'https://github.com/example/repo2/pull/456'
            Repository = 'example/repo2'
            Number = 456
            CreatedAt = [DateTime]::Parse('2025-12-03 09:00:00')
            UpdatedAt = [DateTime]::Parse('2025-12-06 16:45:00')
            Author = 'jane_smith'
            Labels = @('bug', 'high-priority')
        },
        [PSCustomObject]@{
            Title = 'Update documentation for API endpoints'
            Url = 'https://github.com/example/repo1/pull/789'
            Repository = 'example/repo1'
            Number = 789
            CreatedAt = [DateTime]::Parse('2025-12-04 11:20:00')
            UpdatedAt = [DateTime]::Parse('2025-12-07 10:30:00')
            Author = 'doc_writer'
            Labels = @('documentation')
        }
    )
    
    Write-Host "Generating email for scenario: Multiple PRs assigned"
    Write-Host ("-" * 70)
    
    $htmlBody = Format-EmailBody -PullRequests $samplePrs -Username "demo_user"
    
    # Save to file for viewing
    $tempDir = if ($env:TEMP) { $env:TEMP } elseif ($env:TMPDIR) { $env:TMPDIR } else { '/tmp' }
    $outputFile = Join-Path $tempDir "demo_email.html"
    $htmlBody | Out-File -FilePath $outputFile -Encoding UTF8
    
    Write-Host "Generated email with $($samplePrs.Count) pull requests"
    Write-Host "Email HTML saved to: $outputFile"
    Write-Host ""
    Write-Host "Summary of PRs in the email:"
    foreach ($pr in $samplePrs) {
        Write-Host "  • $($pr.Repository)#$($pr.Number): $($pr.Title)"
        Write-Host "    Author: $($pr.Author) | Labels: $($pr.Labels -join ', ')"
    }
    Write-Host ""
    
    # Demo: No PRs
    Write-Host ("-" * 70)
    Write-Host "Generating email for scenario: No PRs assigned"
    Write-Host ("-" * 70)
    
    $htmlBodyEmpty = Format-EmailBody -PullRequests @() -Username "demo_user"
    
    $outputFileEmpty = Join-Path $tempDir "demo_email_empty.html"
    $htmlBodyEmpty | Out-File -FilePath $outputFileEmpty -Encoding UTF8
    
    Write-Host "Email HTML saved to: $outputFileEmpty"
    Write-Host ""
    
    Write-Host ("=" * 70)
    Write-Host "Demo completed successfully!"
    Write-Host ("=" * 70)
    Write-Host ""
    Write-Host "To view the generated emails, open the HTML files in a web browser:"
    Write-Host "  - $outputFile"
    Write-Host "  - $outputFileEmpty"
    Write-Host ""
}

# Run the demo
try {
    Show-DemoEmailFormatting
}
catch {
    Write-Error "Demo failed: $_"
    exit 1
}
