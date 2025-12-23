# Sanitized artifact (015)
# Notes: identifiers/secrets replaced with <REDACTED_*> placeholders.
# Source: <REDACTED_PATH>
# project-contents.ps1
# Reads contents of all relevant source files into one output file.

$Root = "C:\src\razzberry-backend"
$OutputFile = "C:\Temp\razzberry\Scripts\assessment results\contents.txt"

$includeExts = @("*.js", "*.ts", "*.tsx", "*.jsx", "*.json", "*.toml", "*.yml", "*.yaml", "*.env*", "*.md", "*.ps1", "*.sh", "*.html", "*.css", "*.prisma")
$excludeDirs = @("node_modules", ".git", ".next", ".output", "dist", "build", "logs", "__pycache__")

$files = Get-ChildItem -Path $Root -Recurse -File -Include $includeExts | Where-Object {
  $rel = $_.FullName.Substring($Root.Length + 1)
  $excludeDirs -notcontains ($rel.Split('\')[0])
}

@() | Out-File $OutputFile  # clear file

foreach ($file in $files) {
  Add-Content $OutputFile "`n===== FILE: $($file.FullName) =====`n"
  Get-Content $file.FullName -Raw | Add-Content $OutputFile
}
Write-Host "✅ Full contents dump saved to $OutputFile"

