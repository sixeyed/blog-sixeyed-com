#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Runs the Jekyll blog locally using Docker
.DESCRIPTION
    This script starts the Jekyll development server in a Docker container with live reload enabled.
    The site will be available at http://localhost:4000
.PARAMETER Staging
    Run with staging configuration (_config.yml + _config_staging.yml)
.PARAMETER Port
    Specify a custom port (default: 4000)
.PARAMETER Drafts
    Include draft posts in the build
.PARAMETER Clean
    Clean the Docker environment before starting
.EXAMPLE
    ./serve-docker.ps1
    Runs the site locally with production config using Docker
.EXAMPLE
    ./serve-docker.ps1 -Staging
    Runs the site with staging configuration using Docker
.EXAMPLE
    ./serve-docker.ps1 -Drafts -Port 4001
    Runs the site including drafts on port 4001 using Docker
#>

param(
    [switch]$Staging,
    [int]$Port = 4000,
    [switch]$Drafts,
    [switch]$Clean
)

Write-Host "🐳 Starting Jekyll development server with Docker..." -ForegroundColor Green

# Check if Docker is available
if (!(Get-Command "docker" -ErrorAction SilentlyContinue)) {
    Write-Error "Docker not found. Please install Docker first."
    exit 1
}

# Clean up if requested
if ($Clean) {
    Write-Host "🧹 Cleaning Docker environment..." -ForegroundColor Yellow
    docker system prune -f | Out-Null
}

# Build the Docker command
$dockerArgs = @(
    "run", "--rm", "-it",
    "--volume", "${PWD}:/srv/jekyll",
    "--volume", "blog_bundle_cache:/usr/local/bundle",
    "--publish", "${Port}:4000",
    "--publish", "35729:35729"
)

# Set environment variables
$envVars = @()
if ($Staging) {
    $envVars += @("--env", "JEKYLL_CONFIG=_config.yml,_config_staging.yml")
    Write-Host "📝 Using staging configuration" -ForegroundColor Yellow
    $siteUrl = "http://localhost:$Port (staging config)"
} else {
    $envVars += @("--env", "JEKYLL_CONFIG=_config.yml")
    $siteUrl = "http://localhost:$Port"
}

$dockerArgs += $envVars

# Jekyll image and command
$dockerArgs += @("jekyll/jekyll:4.2.2")

# Build Jekyll serve command
$jekyllCmd = @("jekyll", "serve", "--host", "0.0.0.0", "--livereload", "--livereload-port", "35729")

if ($Drafts) {
    $jekyllCmd += "--drafts"
    $jekyllCmd += "--future"
    Write-Host "📝 Including draft posts (including future-dated)" -ForegroundColor Yellow
}

$dockerArgs += $jekyllCmd

# Generate redirect pages before starting Jekyll
Write-Host "🔗 Generating redirect pages..." -ForegroundColor Yellow
try {
    pwsh ./generate-redirects.ps1 | Out-Null
    Write-Host "✅ Redirect pages updated" -ForegroundColor Green
} catch {
    Write-Warning "Failed to generate redirects: $_"
}
Write-Host ""

Write-Host "🌐 Site will be available at: $siteUrl" -ForegroundColor Cyan
Write-Host "⚡ Live reload enabled - changes will auto-refresh" -ForegroundColor Cyan
Write-Host "💾 Bundle cache volume: blog_bundle_cache" -ForegroundColor Cyan
Write-Host "❌ Press Ctrl+C to stop the server" -ForegroundColor Gray
Write-Host ""

# Start the container
try {
    Write-Host "🔨 Building site and starting server..." -ForegroundColor Yellow
    & docker $dockerArgs
} catch {
    Write-Error "Failed to start Jekyll Docker container: $_"
    exit 1
} finally {
    Write-Host ""
    Write-Host "🛑 Jekyll server stopped" -ForegroundColor Red
}