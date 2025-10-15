param(
  [int]$ApiPort = 8000,
  [int]$WebPort = 3000
)

$ErrorActionPreference = "Stop"

# Resolve project root (directory of this script)
$ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ROOT

# --- Backend (FastAPI) venv activation only ---
$venvPath = Join-Path $ROOT ".venv"
$activatePath = Join-Path $venvPath "Scripts\Activate.ps1"

if (-not (Test-Path $activatePath)) {
  Write-Error "Virtual env not found at '$venvPath'. Please create it (python -m venv .venv) and install requirements first."
  exit 1
}

# --- Frontend (Next.js) setup ---
$frontendDir = Join-Path $ROOT "frontend"
$frontendExists = Test-Path $frontendDir
if (-not $frontendExists) {
  Write-Warning "[Frontend] Directory '$frontendDir' not found. Skipping frontend startup."
}

# Prepare frontend install command
$frontendCmd = @()
$frontendCmd += "Set-Location `"$frontendDir`""
$frontendCmd += "if (-not (Test-Path node_modules)) { npm install }"
$frontendCmd += "npm run dev -- --port $WebPort"
$frontendCommandString = $frontendCmd -join "; "

# Prepare backend run command
$backendCmd = @()
$backendCmd += "Set-Location `"$ROOT`""
$backendCmd += ". `"$activatePath`""
$backendCmd += "uvicorn api.main:app --reload --host 0.0.0.0 --port $ApiPort"
$backendCommandString = $backendCmd -join "; "

# Launch both in separate PowerShell windows
if ($frontendExists) {
  Write-Host "[Frontend] Starting Next.js dev server on port $WebPort" -ForegroundColor Green
  Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-Command", $frontendCommandString | Out-Null
}

Write-Host "[Backend] Starting FastAPI server on port $ApiPort" -ForegroundColor Green
Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-Command", $backendCommandString | Out-Null

Write-Host "Both servers launched in separate windows. Press Ctrl+C to exit this bootstrapper window." -ForegroundColor Yellow
