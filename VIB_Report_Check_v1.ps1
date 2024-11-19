# Version 1.0
# 2024-11-14
# Check VIBs script with HTML output
# This script checks if specified VIBs are installed on all hosts in a cluster and writes the output to an HTML file
# Rename VIB01 and VIB02 for the VIB you want to check the availibility
# $outputPath: File location HTML file
# Input vCenter en Cluster: $vCenter & $Cluster

# Function Check VIB
function CheckVIB {
    Param (
        $ESXi  # The EsxCli object
    )

    [array]$arrayvibs = @("VIB01", "VIB02")
    $esxcli = Get-EsxCli -V2 -VMHost $ESXi
    $result = ""

    foreach ($vib in $arrayvibs) {
        if ($esxcli.software.vib.list.Invoke() | Where-Object {$_.Name -eq "$vib"}) {
            $result += "<tr style='background-color: #ffe6e6;'><td>$($ESXi.Name)</td><td>$vib</td><td>Found</td></tr>"
        } else {
            $result += "<tr style='background-color: #e6ffe6;'><td>$($ESXi.Name)</td><td>$vib</td><td>Not Found</td></tr>"
        }
    }

    return $result
}

# vCenter & Cluster Parameters
$vCenter = "FQDN vCenter"
$cluster = "Cluster"

# Connect vCenter
Try {Disconnect-VIServer * -Confirm:$false -ErrorAction SilentlyContinue | Out-Null}
Catch {}

Connect-VIServer $vCenter

$ESXis = Get-Cluster -Name $cluster | Get-VMHost | Sort-Object Name | Where-Object {$_.ConnectionState -eq 'Connected' -or $_.ConnectionState -eq 'Maintenance'}

# HTML header
$html = @"
<html>
<head>
    <title>VIB Check Report</title>
    <style>
        table { width: 100%; border-collapse: collapse; }
        th, td { border: 1px solid black; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>VIB Check Report</h1>
    <table>
        <tr>
            <th>Host</th>
            <th>VIB</th>
            <th>Status</th>
        </tr>
"@

foreach ($ESXi in $ESXis) {
    $html += CheckVIB -ESXi $ESXi
}

# HTML footer with creation date and time
$creationDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$html += @"
    </table>
    <p>Report generated on: $creationDate</p>
</body>
</html>
"@

# Output HTML to file
$outputPath = "C:\Scripts\VIB_Check_Report.html"
$html | Out-File -FilePath $outputPath

# Open the HTML file in Microsoft Edge
Start-Process "msedge.exe" $outputPath

# Disconnect vCenter
Write-Host "Disconnecting vCenter $vCenter"
Disconnect-VIServer -Confirm:$False | Out-Null

Write-Host "Report generated at $outputPath"