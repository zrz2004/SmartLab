$backendRoot = Split-Path -Parent $PSScriptRoot
$pidFile = Join-Path $backendRoot '.server.pid'

if (-not (Test-Path $pidFile)) {
  Write-Output 'SmartLab backend is not running.'
  exit 0
}

$serverPid = Get-Content $pidFile -ErrorAction SilentlyContinue
if ($serverPid -and (Get-Process -Id $serverPid -ErrorAction SilentlyContinue)) {
  Stop-Process -Id $serverPid -Force
}

Remove-Item $pidFile -ErrorAction SilentlyContinue
Write-Output 'SmartLab backend stopped.'
