# setup_scheduler.ps1 — Chay 1 lan de tao 3 scheduled tasks
$script = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File '$PSScriptRoot\auto_summarize.ps1'"

$tasks = @(
    @{ Name = "DiscordSummarizer-9AM";  Time = "09:00" },
    @{ Name = "DiscordSummarizer-12PM"; Time = "12:00" },
    @{ Name = "DiscordSummarizer-18PM"; Time = "18:00" }
)

foreach ($t in $tasks) {
    schtasks /delete /tn $t.Name /f 2>$null | Out-Null
    $result = schtasks /create /tn $t.Name /tr $script /sc DAILY /st $t.Time /f
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Task '$($t.Name)' -> chay luc $($t.Time) moi ngay"
    } else {
        Write-Host "[FAIL] Khong tao duoc task '$($t.Name)'"
    }
}

Write-Host ""
Write-Host "Kiem tra trong Task Scheduler: taskschd.msc"
Write-Host "Chay thu ngay: Start-ScheduledTask -TaskName 'DiscordSummarizer-9AM'"
