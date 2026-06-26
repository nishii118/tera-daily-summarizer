# export_daily.ps1
# Moi lan chay chi export tin nhan moi tu lan chay truoc den hien tai
$ErrorActionPreference = "Stop"

# Doc .env
Get-Content (Join-Path $PSScriptRoot ".env") | ForEach-Object {
    if ($_ -match "^\s*([^#=][^=]*)=(.*)$") {
        [System.Environment]::SetEnvironmentVariable($Matches[1].Trim(), $Matches[2].Trim())
    }
}

$USER_TOKEN   = $env:DISCORD_USER_TOKEN
$GUILD_ID     = $env:SERVER_A_GUILD_ID
$CATEGORY_IDS = $env:SOURCE_CATEGORY_IDS -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ }
$DCE          = Join-Path $PSScriptRoot "dce\DiscordChatExporter.Cli.exe"
$LAST_RUN_FILE = Join-Path $PSScriptRoot "last_run.txt"

# Xac dinh khoang thoi gian export
$now = Get-Date

if (Test-Path $LAST_RUN_FILE) {
    $afterTime = [datetime]::Parse((Get-Content $LAST_RUN_FILE).Trim())
} else {
    # Lan dau chay: lay tin nhan 24h truoc
    $afterTime = $now.AddHours(-24)
}

$afterStr  = $afterTime.ToString("yyyy-MM-dd HH:mm")
$beforeStr = $now.ToString("yyyy-MM-dd HH:mm")

# Thu muc export theo timestamp de khong ghi de nhau
$runLabel  = $now.ToString("yyyy-MM-dd_HH-mm")
$outputDir = Join-Path $PSScriptRoot "exports\$runLabel"
New-Item -ItemType Directory -Force $outputDir | Out-Null

Write-Host "[INFO] Export tu: $afterStr"
Write-Host "[INFO] Export den: $beforeStr"

# Lay danh sach channels tu Discord API
Write-Host "[INFO] Fetching channels from Server A..."
$headers = @{ Authorization = $USER_TOKEN }
try {
    $allChannels = Invoke-RestMethod -Uri "https://discord.com/api/v10/guilds/$GUILD_ID/channels" -Headers $headers
} catch {
    Write-Error "Khong lay duoc danh sach channels: $_"
    exit 1
}

$targetChannels = $allChannels | Where-Object { $_.type -eq 0 -and $CATEGORY_IDS -contains $_.parent_id }

if (-not $targetChannels) {
    Write-Host "[WARN] Khong tim thay channel nao trong category da chi dinh."
    exit 0
}

Write-Host "[INFO] Tim thay $($targetChannels.Count) channel(s)"

# Export tung channel
$exported = @()
foreach ($ch in $targetChannels) {
    $outFile = Join-Path $outputDir "$($ch.name).txt"
    $dceArgs = @("export", "--token", $USER_TOKEN, "--channel", $ch.id, "--output", $outFile, "--format", "PlainText", "--after", $afterStr, "--before", $beforeStr, "--media", "false")
    & $DCE @dceArgs | Out-Null

    if (Test-Path $outFile) {
        $lineCount = (Get-Content $outFile | Measure-Object -Line).Lines
        if ($lineCount -gt 10) {
            Write-Host "[OK]   #$($ch.name) -> $lineCount lines"
            $exported += $outFile
        } else {
            Remove-Item $outFile
        }
    }
}

# Cap nhat thoi gian lan chay cuoi
$now.ToString("yyyy-MM-dd HH:mm:ss") | Out-File $LAST_RUN_FILE -Encoding utf8

if ($exported.Count -gt 0) {
    Write-Host "[DONE] $($exported.Count) channel(s) co noi dung moi -> $outputDir"
} else {
    # Xoa thu muc rong
    Remove-Item $outputDir -Recurse -Force
    Write-Host "[DONE] Khong co tin nhan moi trong khoang thoi gian nay."
}
