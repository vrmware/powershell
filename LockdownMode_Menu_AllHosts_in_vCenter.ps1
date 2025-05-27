# Prompt for vCenter and connect
Clear-Host
$vCenterServer = Read-Host "Enter the vCenter Server to connect to"
try {
    Connect-VIServer -Server $vCenterServer -ErrorAction Stop
    Write-Host "Connected to $vCenterServer" -ForegroundColor Green
} catch {
    Write-Host "Failed to connect to $vCenterServer. Exiting script." -ForegroundColor Red
    exit
}

function Show-Menu {
    Clear-Host
    Write-Host ""
    Write-Host "======================" -ForegroundColor Cyan
    Write-Host " Lockdown Mode Menu"
    Write-Host "======================" -ForegroundColor Cyan
    Write-Host "0. Show current Lockdown Mode status"
    Write-Host "1. Disable Lockdown Mode (lockdownDisabled)"
    Write-Host "2. Enable Lockdown Mode to 'normal' (lockdownNormal)"
    Write-Host "Q. Quit"
    $choice = Read-Host "Enter your choice (0, 1, 2 or Q)"
    return $choice
}

function Set-LockdownMode {
    param (
        [string]$mode
    )

    $ESXiHosts = Get-VMHost

    foreach ($ESXiHost in $ESXiHosts) {
        try {
            $ESXiHostView = Get-View -Id $ESXiHost.Id
            $accessManager = Get-View -Id $ESXiHostView.ConfigManager.HostAccessManager
            $accessManager.ChangeLockdownMode($mode)
            Write-Host "Lockdown Mode set to '$mode' for $($ESXiHost.Name)" -ForegroundColor Green
        } catch {
            Write-Host "Error on host $($ESXiHost.Name): $_" -ForegroundColor Red
        }
    }
}

function Generate-HTMLReport {
    $ESXiHosts = Get-VMHost
    $rows = @()

    foreach ($ESXiHost in $ESXiHosts) {
        try {
            $lockdownMode = $ESXiHost.ExtensionData.Config.LockdownMode
            $rows += "<tr><td>$($ESXiHost.Name)</td><td>$lockdownMode</td></tr>"
        } catch {
            $rows += "<tr><td>$($ESXiHost.Name)</td><td>Error: $_</td></tr>"
        }
    }

    $html = @"
<html>
<head>
    <title>Lockdown Mode Status</title>
    <style>
        body { font-family: Arial; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h2>Lockdown Mode Status Report</h2>
    <p>Generated on $(Get-Date)</p>
    <table>
        <tr><th>Hostname</th><th>Lockdown Mode</th></tr>
        $($rows -join "`n")
    </table>
</body>
</html>
"@

    $path = "$env:TEMP\\LockdownStatus.html"
    $html | Out-File -FilePath $path -Encoding UTF8
    Start-Process "msedge.exe" $path
}

# Main loop
do {
    $choice = Show-Menu

    switch ($choice.ToLower()) {
        "0" { Generate-HTMLReport }
        "1" { Set-LockdownMode -mode "lockdownDisabled" }
        "2" { Set-LockdownMode -mode "lockdownNormal" }
        "q" {
            Write-Host "Disconnecting from vCenter..." -ForegroundColor Cyan
            Disconnect-VIServer -Server $vCenterServer -Confirm:$false
            Write-Host "Disconnected. Exiting script." -ForegroundColor Cyan
        }
        default { Write-Host "Invalid choice. Please try again." -ForegroundColor Yellow }
    }

} while ($choice.ToLower() -ne "q")
