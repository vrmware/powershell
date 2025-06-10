#This script create a CSV and HTML file that displays the following information of all ESXi hosts in a vCenter
#Hostname, Motherboard& ModelSerialNumber

# Prompt the user for the vCenter server name
$vCenterServer = Read-Host "Enter the name or IP address of the vCenter server"

# Connect to vCenter
Connect-VIServer -Server $vCenterServer

# Retrieve ESXi host information
$esxiHosts = Get-VMHost

$hostInfo = foreach ($ESXiHost in $esxiHosts) {
    $esxcli = Get-EsxCli -VMHost $ESXiHost -V2
    $hardwareInfo = $esxcli.hardware.platform.get.Invoke()

    [PSCustomObject]@{
        Hostname         = $ESXiHost.Name
        MotherboardModel = $hardwareInfo.ProductName
        SerialNumber     = $hardwareInfo.SerialNumber
    }
}

# Paths to CSV and HTML files
$csvPath = "$env:TEMP\\ESXi_Host_Hardware_Info.csv"
$htmlPath = "$env:TEMP\\ESXi_Host_Hardware_Info.html"

# Write to CSV
$hostInfo | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

# Generate HTML file
$htmlContent = @"
<html>
<head>
    <title>ESXi Host Hardware Info</title>
    <style>
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid black; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h2>ESXi Host Hardware Info</h2>
    <table>
        <tr><th>Hostname</th><th>Motherboard Model</th><th>Serial Number</th></tr>
"@

foreach ($item in $hostInfo) {
    $htmlContent += "<tr><td>$($item.Hostname)</td><td>$($item.MotherboardModel)</td><td>$($item.SerialNumber)</td></tr>`n"
}

$htmlContent += @"
    </table>
</body>
</html>
"@

$htmlContent | Out-File -FilePath $htmlPath -Encoding UTF8

# Open HTML in Microsoft Edge
Start-Process "msedge.exe" $htmlPath

# Disconnect from vCenter
Disconnect-VIServer -Server $vCenterServer -Confirm:$false
