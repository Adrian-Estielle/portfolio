# Sanitized artifact (001)
# Notes: identifiers/secrets replaced with <REDACTED_*> placeholders.
# Source: <REDACTED_PATH>
# Service Health Check Script
$ErrorActionPreference = "Stop"

Write-Host "`n🔍 Checking backend API endpoints..." -ForegroundColor Cyan
$apiBase = "http://<REDACTED_HOST>"
$endpoints = @("/health", "/auth/health")

foreach ($ep in $endpoints) {
    try {
        $resp = Invoke-RestMethod -Uri "$apiBase$ep" -Method GET
        Write-Host "✅ $ep → $($resp | ConvertTo-Json -Compress)" -ForegroundColor Green
    } catch {
        Write-Host "❌ $ep failed: $_" -ForegroundColor Red
    }
}

Write-Host "`n🔍 Checking PostgreSQL via Prisma..." -ForegroundColor Cyan
try {
    npx prisma db pull | Out-Null
    Write-Host "✅ Prisma DB pull succeeded" -ForegroundColor Green
} catch {
    Write-Host "❌ Prisma DB pull failed: $_" -ForegroundColor Red
}

Write-Host "`n🔍 Seeding database..." -ForegroundColor Cyan
try {
    node prisma/seed.js
    Write-Host "✅ Seed script ran successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Seed script failed: $_" -ForegroundColor Red
}

Write-Host "`n🔍 Checking SMTP Email (Nodemailer via SendGrid)..." -ForegroundColor Cyan
try {
    $env:SENDGRID_API_KEY = "SG.REDACTED.REDACTED"
    node -e @"
        const nodemailer = require('nodemailer');
        const transporter = nodemailer.createTransport({
            host: 'smtp.sendgrid.net',
            port: 587,
            auth: { user: 'apikey', pass: process.env.SENDGRID_API_KEY }
        });
        transporter.verify((err, success) => {
            if (err) throw err;
            console.log('SMTP connection verified');
        });
"@
} catch {
    Write-Host "❌ SMTP check failed: $_" -ForegroundColor Red
}

