$backendRoot = Split-Path -Parent $PSScriptRoot
$pidFile = Join-Path $backendRoot '.server.pid'
$stdoutFile = Join-Path $backendRoot 'server.out.log'
$stderrFile = Join-Path $backendRoot 'server.err.log'

if (Test-Path $pidFile) {
  $existingPid = Get-Content $pidFile -ErrorAction SilentlyContinue
  if ($existingPid -and (Get-Process -Id $existingPid -ErrorAction SilentlyContinue)) {
    Write-Output "SmartLab backend already running with PID $existingPid"
    exit 0
  }
}

Remove-Item $stdoutFile, $stderrFile -ErrorAction SilentlyContinue

$process = Start-Process `
  -FilePath 'node' `
  -ArgumentList 'src/index.js' `
  -WorkingDirectory $backendRoot `
  -WindowStyle Hidden `
  -RedirectStandardOutput $stdoutFile `
  -RedirectStandardError $stderrFile `
  -PassThru

Set-Content -Path $pidFile -Value $process.Id
Write-Output "SmartLab backend started in background. PID=$($process.Id)"
