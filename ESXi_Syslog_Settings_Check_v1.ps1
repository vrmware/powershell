# Version 1.0
# 2024-11-17
# Check ESXi Syslog Global LogHost script with HTML output
# This script checks if Syslog Global LogHost is configured on all hosts in a datacenter and writes the output to an HTML file

# Connect to vCenter Server
$vCenter = "FQDN vCenter"
Connect-VIServer $vCenter

# Get all ESXi hosts in the cluster
$hosts = get-vmhost

# Initialize HTML content with styles for alternating row colors
$htmlContent = @"
<html>
<head>
    <title>ESXi Syslog Settings</title>
    <style>
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            padding: 8px;
            text-align: left;
            border: 1px solid #ddd;
        }
        tr:nth-child(odd) {
            background-color: white;
        }
        tr:nth-child(even) {
            background-color: lightgrey;
        }
    </style>
</head>
<body>
    <h1>ESXi Syslog Settings</h1>
    <table>
        <tr>
            <th>ESXi Host</th>
            <th>Syslog Global Loghost</th>
        </tr>
"@

# Loop through each ESXi host and get the syslog.global.loghost advanced setting
foreach ($esxi in $hosts) {
    $setting = Get-AdvancedSetting -Entity $esxi -Name 'syslog.global.loghost'
    $htmlContent += "<tr><td>$($esxi.Name)</td><td>$($setting.Value)</td></tr>"
}

# Add the current date and time
$currentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$htmlContent += @"
    </table>
    <p>Report generated on: $currentDateTime</p>
</body>
</html>
"@

# Save HTML content to a file
$outputPath = "C:\Scripts\esxi_syslog_settings.html"
$htmlContent | Out-File -FilePath $outputPath

# Open the HTML file
Start-Process "msedge.exe" $outputPath

# Disconnect from vCenter Server
Disconnect-VIServer -Confirm:$false
