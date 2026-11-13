# Windows Safe Startup & Maintenance Manager
# Compatible with Windows 10/11 PowerShell 5.1+
# Conservative by design: no debloating, service disabling, registry cleaning,
# Defender changes, driver changes, or removal of Windows components.

$ErrorActionPreference = "Continue"
$AppName = "WindowsSafeManager"
$Root = Join-Path $env:ProgramData $AppName
$BackupDir = Join-Path $Root "Backups"
$LogFile = Join-Path $Root "activity.log"
$RunBackupKey = "HKCU:\Software\WindowsSafeManager\DisabledRunEntries"
$RunBackupKeyLM = "HKLM:\Software\WindowsSafeManager\DisabledRunEntries"
$StartupBackup = Join-Path $Root "DisabledStartupFolderItems"

function Initialize-Environment {
    param(
        [string]$Path = $BackupDir,
        [string]$StartupPath = $StartupBackup
    )
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
    if (-not (Test-Path $StartupPath)) {
        New-Item -ItemType Directory -Force -Path $StartupPath | Out-Null
    }
}

function Write-Log([string]$Message) {
    try {
        if (-not (Test-Path $Root)) {
            New-Item -ItemType Directory -Force -Path $Root -ErrorAction SilentlyContinue | Out-Null
        }
        $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $Message"
        Add-Content -Path $LogFile -Value $line -ErrorAction SilentlyContinue
    } catch {
        Write-Verbose "Logging skipped: $($_.Exception.Message)"
    }
}

function Wait-Menu {
    Write-Host ""
    Read-Host "Press Enter to continue" | Out-Null
}

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Confirm-RestorePoint {
    Write-Host "`nCreating a System Restore point..." -ForegroundColor Cyan
    try {
        Enable-ComputerRestore -Drive "$($env:SystemDrive)\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Before WindowsSafeManager changes" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Host "Restore point created." -ForegroundColor Green
        Write-Log "System restore point created."
        return $true
    } catch {
        Write-Host "Could not create a restore point: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "System Protection may be disabled, or Windows may have created a restore point recently."
        Write-Log "Restore point creation failed: $($_.Exception.Message)"
        return $false
    }
}

function Show-StartupItem {
    Write-Host "`n=== Startup applications (current user and all users) ===" -ForegroundColor Cyan
    $items = Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue |
        Select-Object Name, Location, User, Command
    if ($items) { $items | Format-Table -AutoSize -Wrap }
    else { Write-Host "No startup entries were found." }

    Write-Host "`n=== Startup apps reported by Windows ===" -ForegroundColor Cyan
    try {
        Get-CimInstance -Namespace root\cimv2 -ClassName Win32_StartupCommand -ErrorAction Stop |
            Select-Object Name, Location, Command | Format-Table -AutoSize -Wrap
    } catch {
        Write-Verbose "Secondary startup command query skipped: $($_.Exception.Message)"
    }

    Write-Host "`nTip: entries from Settings > Apps > Startup are safest to manage there."
    Write-Host "This script can reversibly disable classic Run-key entries and Startup-folder shortcuts."
    Write-Log "Startup inventory viewed."
}

function Get-RunLocation {
    @(
        @{Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"; Scope="Current user"},
        @{Path="HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"; Scope="All users"},
        @{Path="HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"; Scope="All users (32-bit)"}
    )
}

function Get-RunStartupEntry {
    param(
        [array]$Locations = (Get-RunLocation)
    )
    $all = @()
    foreach ($loc in $Locations) {
        if (Test-Path $loc.Path) {
            $props = (Get-ItemProperty -Path $loc.Path).PSObject.Properties |
                Where-Object { $_.Name -notmatch '^PS(Path|ParentPath|ChildName|Drive|Provider)$' }
            foreach ($prop in $props) {
                $all += [pscustomobject]@{
                    Name  = $prop.Name
                    Value = [string]$prop.Value
                    Path  = $loc.Path
                    Scope = $loc.Scope
                }
            }
        }
    }
    return $all
}

function Backup-RunEntry {
    param(
        [Parameter(Mandatory=$true)]
        [pscustomobject]$Item,
        [string]$CustomBackupKey = $null
    )
    $isMachine = $Item.Path -like "HKLM:*"
    $backupKey = if ($CustomBackupKey) { $CustomBackupKey } elseif ($isMachine) { $RunBackupKeyLM } else { $RunBackupKey }
    if (-not (Test-Path $backupKey)) {
        New-Item -Path $backupKey -Force | Out-Null
    }
    $safeName = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$($Item.Path)|$($Item.Name)"))
    New-ItemProperty -Path $backupKey -Name $safeName -Value $Item.Value -PropertyType String -Force | Out-Null
    return $safeName
}

function Remove-RunStartupEntry {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Name
    )
    if ($PSCmdlet.ShouldProcess("$Path\$Name", "Remove Run startup entry")) {
        Remove-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
    }
}

function Disable-RunEntry {
    $all = Get-RunStartupEntry
    if (-not $all -or $all.Count -eq 0) { Write-Host "No classic Run entries found."; return }

    Write-Host "`nSelect a startup entry to disable (it will be backed up, not deleted):" -ForegroundColor Cyan
    for ($i=0; $i -lt $all.Count; $i++) {
        Write-Host ("[{0}] {1} | {2} | {3}" -f ($i+1), $all[$i].Name, $all[$i].Scope, $all[$i].Value)
    }
    $choice = Read-Host "Enter number, or press Enter to cancel"
    if ($choice -notmatch '^\d+$' -or [int]$choice -lt 1 -or [int]$choice -gt $all.Count) { return }
    $item = $all[[int]$choice-1]

    Write-Host "`nSelected: $($item.Name)" -ForegroundColor Yellow
    Write-Host "Only disable entries you recognize as optional, such as a game launcher or an updater."
    Write-Host "Do NOT disable security software, touchpad/audio/graphics utilities, VPN, backup, or work tools."
    $confirm = Read-Host "Type DISABLE to proceed"
    if ($confirm -cne "DISABLE") { Write-Host "Cancelled."; return }

    $isMachine = $item.Path -like "HKLM:*"
    if ($isMachine -and -not (Test-Admin)) { Write-Host "Run this script as Administrator to change an all-users entry."; return }

    try {
        Backup-RunEntry -Item $item | Out-Null
        Remove-RunStartupEntry -Path $item.Path -Name $item.Name
        Write-Host "Disabled and backed up. Use Restore option in this script to re-enable it." -ForegroundColor Green
        Write-Log "Disabled Run entry: $($item.Name) at $($item.Path)"
    } catch {
        Write-Host "Could not disable entry: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Restore-SingleRunEntry {
    param(
        [Parameter(Mandatory=$true)][string]$BackupKey,
        [Parameter(Mandatory=$true)][string]$EncodedName,
        [Parameter(Mandatory=$true)][string]$Value
    )
    try {
        $decoded = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($EncodedName))
        $parts = $decoded -split '\|', 2
        if ($parts.Count -ne 2) {
            Write-Warning "Skipping invalid backup key format: $EncodedName"
            return $null
        }
        $targetPath, $valueName = $parts
        if (-not (Test-Path $targetPath)) {
            New-Item -Path $targetPath -Force | Out-Null
        }
        New-ItemProperty -Path $targetPath -Name $valueName -Value $Value -PropertyType String -Force | Out-Null
        Remove-ItemProperty -Path $BackupKey -Name $EncodedName -ErrorAction SilentlyContinue
        return [pscustomobject]@{
            Path    = $targetPath
            Name    = $valueName
            Success = $true
        }
    } catch {
        Write-Host "Restore failed for $($EncodedName): $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Restore-RunEntry {
    $restoredCount = 0
    foreach ($pair in @(@{Key=$RunBackupKey; Machine=$false}, @{Key=$RunBackupKeyLM; Machine=$true})) {
        if (-not (Test-Path $pair.Key)) { continue }
        if ($pair.Machine -and -not (Test-Admin)) {
            Write-Host "Administrator rights required to restore all-users startup entries."
            continue
        }
        $props = (Get-ItemProperty -Path $pair.Key).PSObject.Properties |
            Where-Object { $_.Name -notmatch '^PS(Path|ParentPath|ChildName|Drive|Provider)$' }
        foreach ($prop in $props) {
            $restored = Restore-SingleRunEntry -BackupKey $pair.Key -EncodedName $prop.Name -Value ([string]$prop.Value)
            if ($restored -and $restored.Success) {
                $restoredCount++
                Write-Host "Restored: $($restored.Name)" -ForegroundColor Green
                Write-Log "Restored Run entry: $($restored.Name)"
            }
        }
    }
    if ($restoredCount -eq 0) {
        Write-Host "No disabled startup entries found to restore." -ForegroundColor Yellow
    }
}

function Show-ServiceReview {
    Write-Host "`n=== Service review ===" -ForegroundColor Cyan
    Write-Host "No services are changed by this tool. Many services that look unnecessary are required by Windows or hardware."
    Write-Host "Review service name, status and startup type below. Do not disable services just because they are currently stopped."
    try {
        $services = Get-CimInstance Win32_Service -ErrorAction Stop |
            Sort-Object StartMode, DisplayName |
            Select-Object DisplayName, Name, State, StartMode
        $services | Out-GridView -Title "Windows services (read-only review)" -ErrorAction SilentlyContinue
        if (-not $?) {
            $services | Format-Table -AutoSize -Wrap
        }
    } catch {
        Write-Host "Could not query services: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    Write-Log "Service inventory viewed (read-only)."
}

function Show-SafeRecommendation {
    Write-Host @"

SAFE, LOW-RISK RECOMMENDATIONS
1. Startup apps: turn off only apps you recognize and do not need immediately after sign-in.
   Examples often suitable: game launchers, music launchers, chat apps you open manually.
2. Keep enabled: Microsoft Defender/your antivirus, Windows Security notifications,
   audio, graphics, touchpad/hotkey utilities, cloud backup/sync you rely on, VPN/security tools.
3. Storage: use Settings > System > Storage > Temporary files or Storage Sense.
   Review selections before deleting. Do not delete Downloads unless you have checked them.
4. Updates: keep Windows Update, Microsoft Store updates, and device drivers from your PC maker.
5. Privacy: review Settings > Privacy & security. Avoid scripts that disable telemetry wholesale,
   Defender, SmartScreen, Windows Update, or diagnostic/security services.
6. Uninstall apps: use Settings > Apps > Installed apps. Do not remove runtimes, drivers,
   Microsoft Visual C++ packages, .NET, WebView2, or items whose purpose you do not know.
7. Performance: check Task Manager > Processes and Startup apps before changing anything.
8. Keep at least 15-20% free disk space and reboot after updates.

NOT INCLUDED ON PURPOSE
- Bulk debloat scripts or "optimizer" registry tweaks
- Disabling Windows services or scheduled tasks
- Removing built-in Windows apps in bulk
- Disabling Defender, Firewall, SmartScreen, Windows Update, or UAC
- Registry cleaners, RAM cleaners, driver updaters, or undocumented tweaks

These changes can reduce security, break features, or make Windows unstable.
"@
}

function Export-SystemReport {
    param(
        [string]$OutputDirectory = $BackupDir
    )
    if (-not (Test-Path $OutputDirectory)) {
        New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    }
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $report = Join-Path $OutputDirectory "SystemReport-$stamp.txt"
    $osInfo = try {
        (Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).Caption
    } catch {
        [System.Environment]::OSVersion.VersionString
    }
    $startupInfo = try {
        (Get-CimInstance Win32_StartupCommand -ErrorAction Stop | Format-List Name,Location,User,Command | Out-String)
    } catch {
        "Startup command inventory not accessible in current security context: $($_.Exception.Message)`n"
    }
    $installedApps = try {
        (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*,HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue |
            Where-Object DisplayName | Select-Object DisplayName,DisplayVersion,Publisher |
            Sort-Object DisplayName | Format-Table -AutoSize | Out-String)
    } catch {
        "Installed applications inventory not accessible in current security context: $($_.Exception.Message)`n"
    }
    $serviceInfo = try {
        (Get-CimInstance Win32_Service -ErrorAction Stop | Select-Object Name,DisplayName,State,StartMode | Format-Table -AutoSize | Out-String)
    } catch {
        "Service inventory not accessible in current security context: $($_.Exception.Message)`n"
    }
    @(
        "Windows Safe Manager system report"
        "Date: $(Get-Date)"
        "Computer: $env:COMPUTERNAME"
        "Windows: $osInfo"
        "`nStartup entries:"
        $startupInfo
        "`nInstalled applications (registry inventory):"
        $installedApps
        "`nServices (read-only):"
        $serviceInfo
    ) | Out-File -FilePath $report -Encoding UTF8
    Write-Host "Report saved to: $report" -ForegroundColor Green
    Write-Log "System report exported: $report"
}

function Show-RestoreInstruction {
    Write-Host @"

SYSTEM RESTORE
To roll Windows back:
1. Save your work and close apps.
2. Press Win+R, type rstrui.exe, and press Enter.
3. Choose the restore point named "Before WindowsSafeManager changes" (if available).
4. Follow the wizard. Personal files are normally not affected, but apps, drivers and settings
   installed after that restore point may be reverted.

A restore point is not a full backup. Keep a separate backup of important files.
You can also use this tool's Restore disabled startup entries option for changes it made.
"@
}

# Compatibility Aliases
Set-Alias -Name Pause-Menu -Value Wait-Menu -ErrorAction SilentlyContinue
Set-Alias -Name Ensure-RestorePoint -Value Confirm-RestorePoint -ErrorAction SilentlyContinue
Set-Alias -Name Show-StartupItems -Value Show-StartupItem -ErrorAction SilentlyContinue
Set-Alias -Name Get-RunLocations -Value Get-RunLocation -ErrorAction SilentlyContinue
Set-Alias -Name Get-RunStartupEntries -Value Get-RunStartupEntry -ErrorAction SilentlyContinue
Set-Alias -Name Restore-RunEntries -Value Restore-RunEntry -ErrorAction SilentlyContinue
Set-Alias -Name Show-SafeRecommendations -Value Show-SafeRecommendation -ErrorAction SilentlyContinue
Set-Alias -Name Show-RestoreInstructions -Value Show-RestoreInstruction -ErrorAction SilentlyContinue

function Show-MainMenu {
    while ($true) {
        Clear-Host
        Write-Host "===============================================" -ForegroundColor Cyan
        Write-Host "       WINDOWS SAFE STARTUP & MAINTENANCE"
        Write-Host "===============================================" -ForegroundColor Cyan
        Write-Host "Backup/log folder: $Root"
        Write-Host ""
        Write-Host "[1] Create a System Restore point"
        Write-Host "[2] View startup apps"
        Write-Host "[3] Disable one classic startup entry (reversible)"
        Write-Host "[4] Restore startup entries disabled by this tool"
        Write-Host "[5] Review Windows services (read-only)"
        Write-Host "[6] Export system report"
        Write-Host "[7] Show safe recommendations"
        Write-Host "[8] Show how to use System Restore"
        Write-Host "[0] Exit"
        $choice = Read-Host "`nChoose an option"
        switch ($choice) {
            "1" { Confirm-RestorePoint; Wait-Menu }
            "2" { Show-StartupItem; Wait-Menu }
            "3" {
                if (-not (Test-Admin)) {
                    Write-Host "For best results, close this window and run PowerShell as Administrator."
                    Write-Host "Current-user entries may still be manageable without elevation."
                }
                Disable-RunEntry
                Wait-Menu
            }
            "4" { Restore-RunEntry; Wait-Menu }
            "5" { Show-ServiceReview; Wait-Menu }
            "6" { Export-SystemReport; Wait-Menu }
            "7" { Show-SafeRecommendation; Wait-Menu }
            "8" { Show-RestoreInstruction; Wait-Menu }
            "0" { break }
            default { Write-Host "Invalid choice."; Start-Sleep -Seconds 1 }
        }
    }
}

Set-Alias -Name MainMenu -Value Show-MainMenu -ErrorAction SilentlyContinue

# Execute main menu only when run directly, not when dot-sourced for testing
if ($MyInvocation.InvocationName -ne '.') {
    Initialize-Environment
    if (-not (Test-Admin)) {
        Write-Host "Note: Not running as Administrator. Some all-users actions and restore point creation need elevation." -ForegroundColor Yellow
        Write-Host "For full functionality, right-click the file and choose 'Run with PowerShell' after opening PowerShell as Administrator."
    }
    Write-Log "Tool started by $env:USERNAME"
    Show-MainMenu
}
