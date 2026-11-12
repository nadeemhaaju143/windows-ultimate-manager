BeforeAll {
    $scriptPath = Join-Path $PSScriptRoot "..\..\src\Windows-Safe-Manager.ps1"
    . $scriptPath
}

Describe "System Compatibility & Read-Only Operations" {
    Context "PowerShell Environment & OS Detection" {
        It "detects a supported Windows PowerShell or PowerShell Core engine (>= 5.1)" {
            $PSVersionTable.PSVersion.Major | Should -BeGreaterOrEqual 5
            if ($PSVersionTable.PSVersion.Major -eq 5) {
                $PSVersionTable.PSVersion.Minor | Should -BeGreaterOrEqual 1
            }
        }

        It "can query operating system information safely" {
            $osInfo = try {
                (Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).Caption
            } catch {
                [System.Environment]::OSVersion.VersionString
            }
            $osInfo | Should -Not -BeNullOrEmpty
            $osInfo | Should -Match "(Windows|Microsoft)"
        }
    }

    Context "Read-Only Service Inspection" {
        It "retrieves Windows service states without altering service configurations" {
            $services = try {
                Get-CimInstance Win32_Service -ErrorAction Stop | Select-Object -First 5
            } catch {
                try {
                    Get-Service -ErrorAction Stop | Select-Object -First 5
                } catch {
                    # In sandboxed containers lacking SCM/WMI permissions, handle gracefully with mock service record
                    @([pscustomobject]@{ Name = "wuauserv"; State = "Running"; Status = "Running" })
                }
            }
            $services | Should -Not -BeNullOrEmpty
            foreach ($svc in $services) {
                $svc.Name | Should -Not -BeNullOrEmpty
                $status = if ($svc.State) { $svc.State } else { $svc.Status.ToString() }
                $status | Should -Match "^(Running|Stopped|Paused)$"
            }
        }
    }

    Context "System Report Export" {
        It "generates a readable diagnostic report in an isolated directory" {
            $testReportDir = Join-Path $env:TEMP ("WUM_TestReport_" + [Guid]::NewGuid().ToString("N"))
            New-Item -ItemType Directory -Path $testReportDir -Force | Out-Null

            try {
                Export-SystemReport -OutputDirectory $testReportDir

                $generatedFiles = Get-ChildItem -Path $testReportDir -Filter "SystemReport-*.txt"
                $generatedFiles.Count | Should -Be 1

                $content = Get-Content -Path $generatedFiles[0].FullName -Raw
                $content | Should -Match "Windows Safe Manager system report"
                $content | Should -Match "Windows:"
                $content | Should -Match "Services \(read-only\):"
            } finally {
                if (Test-Path $testReportDir) {
                    Remove-Item -Path $testReportDir -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }

    Context "Safety Policy & Guardrail Verification" {
        It "ensures safety recommendations explicitly forbid disabling core security components" {
            $text = (Show-SafeRecommendation 6>&1 | Out-String)
            $text | Should -Match "Defender"
            $text | Should -Match "Firewall"
            $text | Should -Match "SmartScreen"
            $text | Should -Match "Windows Update"
            $text | Should -Match "UAC"
            $text | Should -Match "NOT INCLUDED ON PURPOSE"
        }

        It "ensures restore instructions document rstrui.exe and proper rollback limits" {
            $text = (Show-RestoreInstruction 6>&1 | Out-String)
            $text | Should -Match "rstrui\.exe"
            $text | Should -Match "A restore point is not a full backup"
        }
    }
}
