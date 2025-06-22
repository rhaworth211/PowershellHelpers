param(
    [string]$ModuleName = "DownloadHelpers",
    [string]$ModuleVersion = "1.0.0"
)

$ErrorActionPreference = 'Stop'

Write-Host "Starting Build for $ModuleName..." -ForegroundColor Cyan

# 1. Run Unit Tests
Write-Host "Running Tests..." -ForegroundColor Yellow
$result = Invoke-Pester -Configuration @{
    Run = @{ Path = './tests' }
    Output = @{ Verbosity = 'Detailed' }
}

if ($result.FailedCount -gt 0) {
    throw \"Tests failed! Halting build.\"
}

# 2. Update Version in PSD1
$manifestPath = "./$ModuleName.psd1"
if (Test-Path $manifestPath) {
    Write-Host "Updating Module Version..." -ForegroundColor Yellow
    Update-ModuleManifest -Path $manifestPath -ModuleVersion $ModuleVersion
}

# 3. Clean old builds
$outputFolder = "./output"
if (Test-Path $outputFolder) {
    Remove-Item -Path $outputFolder -Recurse -Force
}
New-Item -Path $outputFolder -ItemType Directory | Out-Null

# 4. Copy Module files
Write-Host "Packaging Module..." -ForegroundColor Yellow
$moduleOutputPath = Join-Path -Path $outputFolder -ChildPath $ModuleName
New-Item -Path $moduleOutputPath -ItemType Directory | Out-Null

Copy-Item -Path "./$ModuleName.psm1", "./$ModuleName.psd1" -Destination $moduleOutputPath

# 5. Zip the module
Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
$zipFile = "./$outputFolder/$ModuleName-$ModuleVersion.zip"
[System.IO.Compression.ZipFile]::CreateFromDirectory($moduleOutputPath, $zipFile)

Write-Host "Build Completed! Output: $zipFile" -ForegroundColor Green
