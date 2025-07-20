# ICS-ADCheck.ps1
# Lightweight Active Directory & Host Control Audit for ICS/OT Workstations
# Author: [Your Name]
# Version: 0.1

Write-Host "`nICS AD Integration Health Check" -ForegroundColor Cyan
Write-Host "--------------------------------`n"

# Check Domain Join Status
$domain = (Get-WmiObject Win32_ComputerSystem).Domain
if ($domain -ne $env:COMPUTERNAME) {
    Write-Host "[+] Domain Join Status: $domain (OK)" -ForegroundColor Green
} else {
    Write-Host "[!] Domain Join Status: Not Joined to a Domain" -ForegroundColor Red
}

# Check System Time Sync Status
try {
    $w32tm = w32tm /query /status 2>$null
    if ($w32tm) {
        Write-Host "[+] Time Sync: OK (w32time responses found)" -ForegroundColor Green
    } else {
        Write-Host "[!] Time Sync: No NTP sync or w32time status unavailable" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[!] Time Sync: Error checking time service" -ForegroundColor Yellow
}

# Check if Local Administrator Account is Enabled
$localAdmin = Get-LocalUser -Name "Administrator" -ErrorAction SilentlyContinue
if ($localAdmin -and $localAdmin.Enabled) {
    Write-Host "[!] Local Admin Account: ENABLED (Not Recommended)" -ForegroundColor Yellow
} else {
    Write-Host "[+] Local Admin Account: Disabled or Renamed" -ForegroundColor Green
}

# Check ICS-specific AD Group Membership (example)
$icsGroupName = "ICSTechs"  # Customize to your environment
try {
    $members = Get-ADGroupMember -Identity $icsGroupName -ErrorAction Stop
    Write-Host "[+] ICS AD Group '$icsGroupName' Found - Members:"
    $members | ForEach-Object { Write-Host "    - $($_.SamAccountName)" }
} catch {
    Write-Host "[!] ICS AD Group '$icsGroupName' Not Found or No Access" -ForegroundColor Yellow
}

# Check if USB Storage Policy is Set
$usbPolicy = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR" -Name "Start" -ErrorAction SilentlyContinue
if ($usbPolicy.Start -eq 4) {
    Write-Host "[+] USB Storage: Blocked via Registry GPO" -ForegroundColor Green
} else {
    Write-Host "[!] USB Storage: Enabled or Not Managed (Check GPO)" -ForegroundColor Yellow
}

# Check RDP Network Level Auth (NLA)
$nla = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -ErrorAction SilentlyContinue
if ($nla.UserAuthentication -eq 1) {
    Write-Host "[+] RDP NLA: ENABLED" -ForegroundColor Green
} else {
    Write-Host "[!] RDP NLA: Disabled or Not Configured" -ForegroundColor Yellow
}

# Check Login Banner Presence
try {
    $legalText = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name LegalNoticeCaption,LegalNoticeText -ErrorAction SilentlyContinue
    if ($legalText.LegalNoticeText) {
        Write-Host "[+] Interactive Logon Banner: PRESENT" -ForegroundColor Green
    } else {
        Write-Host "[!] Interactive Logon Banner: NOT SET" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[!] Interactive Logon Banner: Could Not Verify" -ForegroundColor Yellow
}

# Summary (Optional)
Write-Host "`n-- End of ICS AD Integration Audit --`n" -ForegroundColor Cyan