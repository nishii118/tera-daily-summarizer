# auto_summarize.ps1 — Export + claude tom tat (chi in text) + PowerShell gui webhook
# Kien truc: claude KHONG goi mang (tranh bi chan headless). Wrapper nay lo viec gui.
# Chi tom tat folder do CHINH lan chay nay tao ra & co noi dung -> khong gui trung.
$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot

# Ep UTF-8 de tieng Viet tu claude khong bi loi font (mojibake)
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    chcp 65001 | Out-Null
} catch {}

# Thu muc log
$logDir = Join-Path $PSScriptRoot "logs"
New-Item -ItemType Directory -Force $logDir | Out-Null
$stamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
$log   = Join-Path $logDir "auto_$stamp.log"

function Log($msg) {
    "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg" | Tee-Object -FilePath $log -Append
}

$exportsDir = Join-Path $PSScriptRoot "exports"

Log "=== Bat dau auto_summarize ==="

# Ghi nho danh sach folder TRUOC khi export
$before = @(Get-ChildItem -Path $exportsDir -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)

# 1) Export tin nhan moi
Log "Buoc 1: export_daily.ps1"
powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "export_daily.ps1") *>> $log

# Tim folder MOI (do lan chay nay tao) co chua file .txt
$after = @(Get-ChildItem -Path $exportsDir -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
$newFolders = $after | Where-Object { $_ -notin $before }
$target = $newFolders |
          Where-Object { Get-ChildItem (Join-Path $exportsDir $_) -Filter *.txt -ErrorAction SilentlyContinue } |
          Sort-Object | Select-Object -Last 1

if (-not $target) {
    Log "Khong co tin nhan moi (khong co folder moi co noi dung) -> bo qua tom tat."
    Log "=== Xong auto_summarize ==="
    exit 0
}
Log "Folder moi co noi dung: $target"

# 2) Goi claude headless: CHI in ra tom tat, KHONG goi mang
$claude = Join-Path $env:APPDATA "npm\claude.cmd"
if (-not (Test-Path $claude)) { Log "[LOI] Khong tim thay claude CLI tai $claude"; exit 1 }

$prompt = @"
Doc tat ca file .txt trong thu muc export: exports/$target/
Bo qua file co 'Exported 0 message(s)' hoac rong.
Tom tat noi dung theo tung kenh co hoat dong, tieng Viet, ngan gon, co emoji va ten kenh.
QUAN TRONG:
- CHI IN RA noi dung tom tat thuan text. KHONG chay bat ky script nao, KHONG goi webhook, KHONG gui Discord. Mot script ben ngoai se lo viec gui.
- KHONG hoi lai, KHONG them cau dan/cau ket nhu 'Ban co muon gui khong'. Chi in dung phan tom tat.
"@

Log "Buoc 2: claude -p (chi in tom tat) - model Haiku de tiet kiem token"
$summary = (& $claude -p $prompt --model claude-haiku-4-5-20251001) | Out-String
# Luu ban tom tat sach (UTF-8) de tien kiem tra/debug
Set-Content -Path (Join-Path $logDir "last_summary.txt") -Value $summary -Encoding UTF8
Add-Content -Path $log -Value $summary -Encoding UTF8

# 3) Gui webhook (goi TRONG CUNG tien trinh de khong hong encoding khi truyen tham so)
# Chan cac thong bao loi/het han muc cua claude -> khong gui rac len Discord
$isError = $summary -match "session limit|usage limit|rate limit|hit your|Invalid API|Execution error|Please run /login|Credit balance|quota"
if ($isError) {
    Log "[LOI] claude tra ve loi/het han muc -> KHONG gui. Noi dung: $($summary.Trim())"
} elseif ($summary.Trim().Length -gt 60) {
    Log "Buoc 3: gui webhook"
    & (Join-Path $PSScriptRoot "post_webhook.ps1") -Message $summary *>> $log
} else {
    Log "Tom tat rong/qua ngan -> khong gui."
}

Log "=== Xong auto_summarize ==="
