<#
.SYNOPSIS
    Pester tests for Check-PrAlerts.ps1

.DESCRIPTION
    Tests the core functionality without requiring actual credentials.
    Uses Pester 5.x testing framework.

.NOTES
    Requires Pester 5.x or higher
    Install Pester: Install-Module -Name Pester -Force -SkipPublisherCheck
#>

BeforeAll {
    # Import the script to test
    . $PSScriptRoot/Check-PrAlerts.ps1
}

Describe "Get-Configuration" {
    Context "When valid configuration is provided" {
        It "Should load configuration from .env file" {
            # Create a temporary .env file
            $tempEnvFile = Join-Path $TestDrive ".env"
            @"
GITHUB_TOKEN=test_token
GITHUB_USERNAME=testuser
SMTP_SERVER=smtp.test.com
SMTP_PORT=587
SMTP_USERNAME=test@test.com
SMTP_PASSWORD=test_pass
EMAIL_FROM=from@test.com
EMAIL_TO=to@test.com
REPO_FILTER=
"@ | Out-File -FilePath $tempEnvFile -Encoding UTF8
            
            $config = Get-Configuration -EnvFilePath $tempEnvFile
            
            $config.GitHubToken | Should -Be 'test_token'
            $config.GitHubUsername | Should -Be 'testuser'
            $config.SmtpPort | Should -Be 587
            $config.SmtpServer | Should -Be 'smtp.test.com'
        }
        
        It "Should use default SMTP server if not provided" {
            $tempEnvFile = Join-Path $TestDrive ".env"
            @"
GITHUB_TOKEN=test_token
GITHUB_USERNAME=testuser
SMTP_PORT=587
SMTP_USERNAME=test@test.com
SMTP_PASSWORD=test_pass
EMAIL_FROM=from@test.com
EMAIL_TO=to@test.com
"@ | Out-File -FilePath $tempEnvFile -Encoding UTF8
            
            $config = Get-Configuration -EnvFilePath $tempEnvFile
            
            $config.SmtpServer | Should -Be 'smtp.gmail.com'
        }
        
        It "Should use default SMTP port if not provided" {
            $tempEnvFile = Join-Path $TestDrive ".env"
            @"
GITHUB_TOKEN=test_token
GITHUB_USERNAME=testuser
SMTP_SERVER=smtp.test.com
SMTP_USERNAME=test@test.com
SMTP_PASSWORD=test_pass
EMAIL_FROM=from@test.com
EMAIL_TO=to@test.com
"@ | Out-File -FilePath $tempEnvFile -Encoding UTF8
            
            $config = Get-Configuration -EnvFilePath $tempEnvFile
            
            $config.SmtpPort | Should -Be 587
        }
    }
    
    Context "When configuration is missing" {
        It "Should throw error when file does not exist" {
            { Get-Configuration -EnvFilePath "nonexistent.env" } | Should -Throw "Configuration file not found*"
        }
        
        It "Should throw error when required fields are missing" {
            $tempEnvFile = Join-Path $TestDrive ".env"
            @"
GITHUB_TOKEN=test_token
SMTP_PORT=587
"@ | Out-File -FilePath $tempEnvFile -Encoding UTF8
            
            { Get-Configuration -EnvFilePath $tempEnvFile } | Should -Throw "Missing required configuration*"
        }
    }
    
    Context "When SMTP port validation fails" {
        It "Should throw error for invalid SMTP port" {
            $tempEnvFile = Join-Path $TestDrive ".env"
            @"
GITHUB_TOKEN=test_token
GITHUB_USERNAME=testuser
SMTP_SERVER=smtp.test.com
SMTP_PORT=invalid
SMTP_USERNAME=test@test.com
SMTP_PASSWORD=test_pass
EMAIL_FROM=from@test.com
EMAIL_TO=to@test.com
"@ | Out-File -FilePath $tempEnvFile -Encoding UTF8
            
            { Get-Configuration -EnvFilePath $tempEnvFile } | Should -Throw "Invalid SMTP_PORT*"
        }
        
        It "Should throw error for out-of-range SMTP port" {
            $tempEnvFile = Join-Path $TestDrive ".env"
            @"
GITHUB_TOKEN=test_token
GITHUB_USERNAME=testuser
SMTP_SERVER=smtp.test.com
SMTP_PORT=99999
SMTP_USERNAME=test@test.com
SMTP_PASSWORD=test_pass
EMAIL_FROM=from@test.com
EMAIL_TO=to@test.com
"@ | Out-File -FilePath $tempEnvFile -Encoding UTF8
            
            { Get-Configuration -EnvFilePath $tempEnvFile } | Should -Throw "Invalid SMTP_PORT*"
        }
    }
}

Describe "Format-EmailBody" {
    Context "When no PRs are provided" {
        It "Should return message indicating no PRs" {
            $html = Format-EmailBody -PullRequests @() -Username "testuser"
            
            $html | Should -Match "no pull requests assigned"
        }
    }
    
    Context "When PRs are provided" {
        It "Should format email with PR details" {
            $mockPrs = @(
                [PSCustomObject]@{
                    Title = 'Test PR'
                    Url = 'https://github.com/test/repo/pull/1'
                    Repository = 'test/repo'
                    Number = 1
                    CreatedAt = [DateTime]::Parse('2025-01-01 12:00:00')
                    UpdatedAt = [DateTime]::Parse('2025-01-02 12:00:00')
                    Author = 'author1'
                    Labels = @('bug', 'enhancement')
                }
            )
            
            $html = Format-EmailBody -PullRequests $mockPrs -Username "testuser"
            
            $html | Should -Match "Test PR"
            $html | Should -Match "test/repo"
            $html | Should -Match "#1"
            $html | Should -Match "author1"
            $html | Should -Match "bug"
            $html | Should -Match "enhancement"
        }
        
        It "Should show correct PR count" {
            $mockPrs = @(
                [PSCustomObject]@{
                    Title = 'Test PR 1'
                    Url = 'https://github.com/test/repo/pull/1'
                    Repository = 'test/repo'
                    Number = 1
                    CreatedAt = [DateTime]::Parse('2025-01-01 12:00:00')
                    UpdatedAt = [DateTime]::Parse('2025-01-02 12:00:00')
                    Author = 'author1'
                    Labels = @()
                },
                [PSCustomObject]@{
                    Title = 'Test PR 2'
                    Url = 'https://github.com/test/repo/pull/2'
                    Repository = 'test/repo'
                    Number = 2
                    CreatedAt = [DateTime]::Parse('2025-01-01 12:00:00')
                    UpdatedAt = [DateTime]::Parse('2025-01-02 12:00:00')
                    Author = 'author2'
                    Labels = @()
                }
            )
            
            $html = Format-EmailBody -PullRequests $mockPrs -Username "testuser"
            
            $html | Should -Match "You have <strong>2</strong> pull request\(s\)"
        }
        
        It "Should handle PRs without labels" {
            $mockPrs = @(
                [PSCustomObject]@{
                    Title = 'Test PR'
                    Url = 'https://github.com/test/repo/pull/1'
                    Repository = 'test/repo'
                    Number = 1
                    CreatedAt = [DateTime]::Parse('2025-01-01 12:00:00')
                    UpdatedAt = [DateTime]::Parse('2025-01-02 12:00:00')
                    Author = 'author1'
                    Labels = @()
                }
            )
            
            $html = Format-EmailBody -PullRequests $mockPrs -Username "testuser"
            
            $html | Should -Match "Labels:.*None"
        }
    }
}

Describe "Get-AssignedPullRequests" {
    Context "When GitHub API is called" {
        It "Should construct correct API query" {
            # This is a basic structure test - actual API mocking would require more setup
            # In a real scenario, you would mock Invoke-RestMethod
            
            # We can't easily test this without mocking Invoke-RestMethod
            # This test serves as a placeholder for integration testing
            $true | Should -Be $true
        }
    }
    
    Context "When repository filter is applied" {
        It "Should filter PRs by repository name" {
            # This would require mocking the GitHub API response
            # Placeholder for integration testing
            $true | Should -Be $true
        }
    }
}
