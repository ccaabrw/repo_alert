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

# Import the email formatting function from the main script
. (Join-Path $PSScriptRoot "Check-PrAlerts.ps1")

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
    $outputFile = "/tmp/demo_email.html"
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
    
    $outputFileEmpty = "/tmp/demo_email_empty.html"
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
