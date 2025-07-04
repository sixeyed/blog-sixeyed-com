#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Generates redirect pages from _data/redirects.yml
.DESCRIPTION
    This script reads the redirects.yml file and creates individual redirect pages
    in the /l/ directory. Run this before committing to update redirects.
.EXAMPLE
    ./generate-redirects.ps1
#>

Write-Host "🔗 Generating redirect pages..." -ForegroundColor Green

# Check if redirects.yml exists
$redirectsFile = "_data/redirects.yml"
if (!(Test-Path $redirectsFile)) {
    Write-Error "Redirects file not found: $redirectsFile"
    exit 1
}

# Parse YAML (simple parser for our use case)
$content = Get-Content $redirectsFile -Raw
$inRedirects = $false
$redirects = @()

foreach ($line in $content -split "`n") {
    if ($line -match "^redirects:") {
        $inRedirects = $true
        continue
    }
    
    if ($inRedirects) {
        if ($line -match "^\s*- slug:\s*(.+)") {
            $currentRedirect = @{ slug = $matches[1].Trim() }
        }
        elseif ($line -match "^\s*url:\s*(.+)" -and $currentRedirect) {
            $currentRedirect.url = $matches[1].Trim()
        }
        elseif ($line -match "^\s*description:\s*(.+)" -and $currentRedirect) {
            $currentRedirect.description = $matches[1].Trim()
            $redirects += $currentRedirect
            $currentRedirect = $null
        }
        elseif ($line -match "^\s*$" -and $currentRedirect -and $currentRedirect.url) {
            # Handle redirects without description
            $redirects += $currentRedirect
            $currentRedirect = $null
        }
    }
}

# Add last redirect if exists
if ($currentRedirect -and $currentRedirect.url) {
    $redirects += $currentRedirect
}

Write-Host "Found $($redirects.Count) redirects to generate" -ForegroundColor Cyan

# Create redirect pages
foreach ($redirect in $redirects) {
    $filePath = "l/$($redirect.slug).html"
    
    $content = @"
---
layout: redirect
redirect_to: $($redirect.url)
permalink: /l/$($redirect.slug)/
sitemap: false
---
"@
    
    Set-Content -Path $filePath -Value $content -Force
    Write-Host "✅ Created: $filePath" -ForegroundColor Gray
}

Write-Host "`n✨ Generated $($redirects.Count) redirect pages!" -ForegroundColor Green
Write-Host "Don't forget to commit the changes in the /l/ directory" -ForegroundColor Yellow