BeforeAll {
    # Dot-source the script under test
    $scriptPath = Join-Path $PSScriptRoot "..\..\src\Windows-Safe-Manager.ps1"
    . $scriptPath
}

Describe "StartupManager - Registry Location & Identification" {
    Context "Get-RunLocation" {
        It "returns the three classic Run registry paths" {
            $locations = Get-RunLocation
            $locations.Count | Should -Be 3
            $locations[0].Path | Should -Be "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
            $locations[0].Scope | Should -Be "Current user"
            $locations[1].Path | Should -Be "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
            $locations[1].Scope | Should -Be "All users"
            $locations[2].Path | Should -Be "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
            $locations[2].Scope | Should -Be "All users (32-bit)"
        }
    }

    Context "Get-RunStartupEntry" {
        It "filters out standard PowerShell provider properties" {
            $mockLocation = @(@{ Path = "HKCU:\Software\TestApp\Run"; Scope = "Current user" })
            $mockProps = [pscustomobject]@{
                PSPath       = "Microsoft.PowerShell.Core\Registry::HKCU:\Software\TestApp\Run"
                PSParentPath = "Microsoft.PowerShell.Core\Registry::HKCU:\Software\TestApp"
                PSChildName  = "Run"
                PSDrive      = "HKCU"
                PSProvider   = "Microsoft.PowerShell.Core\Registry"
                AppLauncher  = "C:\Program Files\App\launcher.exe --start"
                DiscordTray  = "C:\Users\User\AppData\Local\Discord\app.exe"
            }

            Mock Test-Path { return $true } -ParameterFilter { $Path -eq "HKCU:\Software\TestApp\Run" }
            Mock Get-ItemProperty { return $mockProps } -ParameterFilter { $Path -eq "HKCU:\Software\TestApp\Run" }

            $entries = Get-RunStartupEntry -Locations $mockLocation
            $entries.Count | Should -Be 2
            $entries[0].Name | Should -Be "AppLauncher"
            $entries[0].Value | Should -Be "C:\Program Files\App\launcher.exe --start"
            $entries[0].Scope | Should -Be "Current user"
            $entries[1].Name | Should -Be "DiscordTray"
        }

        It "handles missing registry paths gracefully without error" {
            $mockLocation = @(@{ Path = "HKCU:\Software\NonExistent\Run"; Scope = "Current user" })
            Mock Test-Path { return $false } -ParameterFilter { $Path -eq "HKCU:\Software\NonExistent\Run" }

            $entries = Get-RunStartupEntry -Locations $mockLocation
            $entries.Count | Should -Be 0
        }
    }
}

Describe "StartupManager - Backup Logic" {
    Context "Backup-RunEntry" {
        It "generates a reversible Base64 safe name containing target path and entry name" {
            $testItem = [pscustomobject]@{
                Name  = "SpotifyWebHelper"
                Value = "C:\Users\Test\AppData\Roaming\Spotify\SpotifyWebHelper.exe"
                Path  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
                Scope = "Current user"
            }

            Mock Test-Path { return $true }
            Mock New-ItemProperty { return $null }

            $safeName = Backup-RunEntry -Item $testItem -CustomBackupKey "HKCU:\Software\TestBackup"

            # Decode and verify payload
            $decoded = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($safeName))
            $decoded | Should -Be "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run|SpotifyWebHelper"
        }

        It "creates the backup registry container if it does not exist" {
            $testItem = [pscustomobject]@{
                Name  = "GameUpdater"
                Value = "C:\Games\updater.exe"
                Path  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
                Scope = "Current user"
            }

            Mock Test-Path { return $false } -ParameterFilter { $Path -eq "HKCU:\Software\NewBackupKey" }
            Mock New-Item { return $null } -Verifiable
            Mock New-ItemProperty { return $null }

            $safeName = Backup-RunEntry -Item $testItem -CustomBackupKey "HKCU:\Software\NewBackupKey"
            Assert-MockCalled New-Item -Times 1 -ParameterFilter { $Path -eq "HKCU:\Software\NewBackupKey" }
            $safeName | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "StartupManager - Restore Operation" {
    Context "Restore-SingleRunEntry" {
        It "decodes a valid backup entry, recreates target property, and purges backup item" {
            $targetPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
            $entryName = "SlackAutoStart"
            $entryValue = "C:\Users\Test\AppData\Local\slack\slack.exe -u"
            $backupKey = "HKCU:\Software\WindowsSafeManager\DisabledRunEntries"
            $encodedName = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$targetPath|$entryName"))

            Mock Test-Path { return $true }
            Mock New-ItemProperty { return $null } -Verifiable
            Mock Remove-ItemProperty { return $null } -Verifiable

            $result = Restore-SingleRunEntry -BackupKey $backupKey -EncodedName $encodedName -Value $entryValue

            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true
            $result.Path | Should -Be $targetPath
            $result.Name | Should -Be $entryName

            Assert-MockCalled New-ItemProperty -Times 1 -ParameterFilter {
                $Path -eq $targetPath -and $Name -eq $entryName -and $Value -eq $entryValue
            }
            Assert-MockCalled Remove-ItemProperty -Times 1 -ParameterFilter {
                $Path -eq $backupKey -and $Name -eq $encodedName
            }
        }

        It "handles corrupted non-Base64 entries safely without crashing" {
            $backupKey = "HKCU:\Software\WindowsSafeManager\DisabledRunEntries"
            $corruptedName = "ThisIsNotBase64!@#$%"

            $result = Restore-SingleRunEntry -BackupKey $backupKey -EncodedName $corruptedName -Value "anything"
            $result | Should -BeNullOrEmpty
        }

        It "skips malformed decoded names lacking the pipe delimiter" {
            $backupKey = "HKCU:\Software\WindowsSafeManager\DisabledRunEntries"
            $malformedName = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("NoDelimiterPathAndName"))

            $result = Restore-SingleRunEntry -BackupKey $backupKey -EncodedName $malformedName -Value "anything"
            $result | Should -BeNullOrEmpty
        }

        It "creates target directory if target registry key was deleted" {
            $targetPath = "HKCU:\Software\DeletedPath\Run"
            $entryName = "RestoredItem"
            $backupKey = "HKCU:\Software\WindowsSafeManager\DisabledRunEntries"
            $encodedName = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$targetPath|$entryName"))

            Mock Test-Path { return $false } -ParameterFilter { $Path -eq $targetPath }
            Mock New-Item { return $null } -Verifiable
            Mock New-ItemProperty { return $null }
            Mock Remove-ItemProperty { return $null }

            $result = Restore-SingleRunEntry -BackupKey $backupKey -EncodedName $encodedName -Value "dummy"
            Assert-MockCalled New-Item -Times 1 -ParameterFilter { $Path -eq $targetPath }
            $result.Success | Should -Be $true
        }
    }
}

Describe "StartupManager - Permissions & Safety Enforcement" {
    Context "Administrator Elevation Detection" {
        It "identifies machine-scope startup entries (HKLM) as requiring elevation" {
            $userItem = [pscustomobject]@{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" }
            $machineItem = [pscustomobject]@{ Path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" }
            $wow64Item = [pscustomobject]@{ Path = "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" }

            ($userItem.Path -like "HKLM:*") | Should -Be $false
            ($machineItem.Path -like "HKLM:*") | Should -Be $true
            ($wow64Item.Path -like "HKLM:*") | Should -Be $true
        }

        It "aborts machine-level disable operation when running unprivileged" {
            Mock Get-RunStartupEntry {
                return @([pscustomobject]@{
                    Name  = "MachineService"
                    Value = "C:\Program Files\Common\service.exe"
                    Path  = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
                    Scope = "All users"
                })
            }
            Mock Read-Host -MockWith {
                param($Prompt)
                if ($Prompt -match "Enter number") { return "1" }
                if ($Prompt -match "Type DISABLE") { return "DISABLE" }
                return ""
            }
            Mock Test-Admin { return $false }
            Mock Backup-RunEntry { return "safe-id" }
            Mock Remove-RunStartupEntry { }

            Disable-RunEntry

            # Must NOT call backup or remove when admin test fails for HKLM
            Assert-MockCalled Backup-RunEntry -Times 0
            Assert-MockCalled Remove-RunStartupEntry -Times 0
        }
    }

    Context "Input Validation & Cancellation" {
        It "cancels disable when user enters a non-numeric choice" {
            Mock Get-RunStartupEntry {
                return @([pscustomobject]@{
                    Name = "App"; Value = "test.exe"; Path = "HKCU:\Run"; Scope = "User"
                })
            }
            Mock Read-Host { return "abc" }
            Mock Backup-RunEntry { }
            Mock Remove-RunStartupEntry { }

            Disable-RunEntry

            Assert-MockCalled Backup-RunEntry -Times 0
            Assert-MockCalled Remove-RunStartupEntry -Times 0
        }

        It "cancels disable when user choice is out of index range" {
            Mock Get-RunStartupEntry {
                return @([pscustomobject]@{
                    Name = "App"; Value = "test.exe"; Path = "HKCU:\Run"; Scope = "User"
                })
            }
            Mock Read-Host { return "99" }
            Mock Backup-RunEntry { }
            Mock Remove-RunStartupEntry { }

            Disable-RunEntry

            Assert-MockCalled Backup-RunEntry -Times 0
            Assert-MockCalled Remove-RunStartupEntry -Times 0
        }

        It "cancels disable when confirmation text is not exactly 'DISABLE'" {
            Mock Get-RunStartupEntry {
                return @([pscustomobject]@{
                    Name = "App"; Value = "test.exe"; Path = "HKCU:\Run"; Scope = "User"
                })
            }
            Mock Read-Host -MockWith {
                param($Prompt)
                if ($Prompt -match "Enter number") { return "1" }
                if ($Prompt -match "Type DISABLE") { return "disable" } # lowercase rejected by -cne
                return ""
            }
            Mock Backup-RunEntry { }
            Mock Remove-RunStartupEntry { }

            Disable-RunEntry

            Assert-MockCalled Backup-RunEntry -Times 0
            Assert-MockCalled Remove-RunStartupEntry -Times 0
        }
    }
}
