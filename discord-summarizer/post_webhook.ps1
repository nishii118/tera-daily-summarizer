# post_webhook.ps1 — Gửi tóm tắt lên Server B qua Discord Webhook
# Dùng: .\post_webhook.ps1 -Message "nội dung tóm tắt"

param(
    [Parameter(Mandatory)]
    [string]$Message
)

# Đọc webhook URL từ .env
$envFile = Join-Path $PSScriptRoot ".env"
Get-Content $envFile | ForEach-Object {
    if ($_ -match "^\s*([^#][^=]+)=(.*)$") {
        [System.Environment]::SetEnvironmentVariable($Matches[1].Trim(), $Matches[2].Trim())
    }
}

$WEBHOOK_URL = $env:SERVER_B_WEBHOOK_URL

if (-not $WEBHOOK_URL) {
    Write-Error "SERVER_B_WEBHOOK_URL chưa được set trong .env"
    exit 1
}

# Discord webhook giới hạn 2000 ký tự mỗi message — tự động chia nhỏ nếu dài
$chunks = @()
$remaining = $Message
while ($remaining.Length -gt 1900) {
    $cut = $remaining.LastIndexOf("`n", 1900)
    if ($cut -le 0) { $cut = 1900 }
    $chunks += $remaining.Substring(0, $cut)
    $remaining = $remaining.Substring($cut).TrimStart()
}
$chunks += $remaining

foreach ($chunk in $chunks) {
    $body  = [ordered]@{ content = $chunk } | ConvertTo-Json -Compress
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
    Invoke-RestMethod -Uri $WEBHOOK_URL -Method Post -ContentType "application/json; charset=utf-8" -Body $bytes | Out-Null
    Start-Sleep -Milliseconds 500
}

Write-Host "[OK] Đã gửi tóm tắt lên Server B ($($chunks.Count) message(s))"
