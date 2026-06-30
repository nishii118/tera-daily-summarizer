# auto_summarize.ps1 — Export + tu dong tom tat + gui Discord (Task Scheduler goi)
# Luong: export_daily.ps1 -> claude -p "tom tat moi nhat" -> post_webhook.ps1 (claude tu goi)
$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot

# Thu muc log
$logDir = Join-Path $PSScriptRoot "logs"
New-Item -ItemType Directory -Force $logDir | Out-Null
$stamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
$log   = Join-Path $logDir "auto_$stamp.log"

function Log($msg) {
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"
    $line | Tee-Object -FilePath $log -Append
}

Log "=== Bat dau auto_summarize ==="

# 1) Export tin nhan moi
Log "Buoc 1: export_daily.ps1"
powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "export_daily.ps1") *>> $log

# 2) Goi claude headless de tom tat + gui webhook (theo CLAUDE.md)
Log "Buoc 2: claude -p 'tom tat moi nhat'"
$claude = Join-Path $env:APPDATA "npm\claude.cmd"
if (-not (Test-Path $claude)) {
    Log "[LOI] Khong tim thay claude CLI tai $claude"
    exit 1
}
& $claude -p "tom tat moi nhat" *>> $log

Log "=== Xong auto_summarize ==="
