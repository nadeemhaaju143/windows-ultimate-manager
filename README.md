# Windows Ultimate Manager

> **"Built by NH Digital. Improved by the community."**

A free, community-driven open-source Windows maintenance, startup inspection, and configuration toolkit.

- **Original Creator**: **Nadeem**, owner of **NH Digital**
- **Organization**: NH Digital
- **Official Website**: [https://nhdigital.shop](https://nhdigital.shop)
- **License**: MIT License ([LICENSE](LICENSE))

---

> [!NOTE]
> **Project Status: Early Prototype (Development Phase)**  
> Windows Ultimate Manager is currently in early prototype development. It is not yet a Version 1.0 or final release. The PowerShell utility provides a conservative, reversible starting point focused on transparency, stability, and safety. Always review script code before execution and test in a virtual machine or non-critical environment.

---

## Mission & Philosophy

Most third-party Windows "optimizers" and "debloaters" apply aggressive, undocumented registry tweaks, disable critical security components (such as Defender, Firewall, SmartScreen, or Windows Update), or terminate core services without user comprehension.

**Windows Ultimate Manager** takes the opposite approach:
1. **Conservative & Reversible**: Every system modification requires explicit confirmation and provides a dedicated rollback path.
2. **Security-First**: Never disable core security protections, essential services, or hardware drivers.
3. **Transparent**: Open source, inspectable PowerShell code with comprehensive automated tests and zero telemetry.
4. **Community-Driven**: Built by NH Digital, improved collaboratively through open community issues, compatibility reports, and pull requests.

---

## Current Implemented Features

The current prototype (`src/Windows-Safe-Manager.ps1`) includes:
- **Startup Inventory**: Scans and displays startup applications across current user and all-users contexts via CIM (`Win32_StartupCommand`).
- **Classic Run-Key Management**:
  - Reversibly disables classic Run registry entries (`HKCU` and `HKLM`).
  - Automatically backs up entries before modification using structured Base64-encoded registry keys.
  - Dedicated restore function to re-enable disabled entries with one click.
- **Read-Only Service Review**: Inspects Windows services, startup types, and running states without altering service configurations.
- **System Diagnostics Export**: Generates a comprehensive, timestamped system report (OS build, startup inventory, installed software, service inventory) to an isolated log directory.
- **Restore Point Guidance**: Attempts creation of a Windows System Restore point (`MODIFY_SETTINGS`) before changes and provides recovery instructions (`rstrui.exe`).
- **Safety Recommendations & Logging**: Clear guidance on safe Windows maintenance practices and transparent activity logging in `$env:ProgramData\WindowsSafeManager\activity.log`.

---

## Planned Features (Roadmap)

The following capabilities are **proposals under evaluation** and are **not yet implemented**:
- GUI interface (only after core engine is thoroughly validated).
- Read-only scheduled task inspector.
- Installed application manager with safe uninstall recommendations.
- Real-time CPU/RAM/background process performance monitoring.
- Signed release packages and checksum verification.

See [ROADMAP.md](ROADMAP.md) for detailed progression milestones.

---

## Safety Guardrails

- **Read Before Running**: Review the PowerShell source code before executing it on your computer.
- **Back Up Your Data**: A restore point or registry backup is never a replacement for a complete backup of important personal files.
- **Virtual Machine Testing**: Test changes on a disposable Windows virtual machine (Hyper-V, VirtualBox, VMware) first.
- **Protected Components**: Windows Ultimate Manager will **NEVER** automatically modify or disable:
  - Microsoft Defender or third-party antivirus
  - Windows Firewall
  - Windows Update
  - User Account Control (UAC)
  - Windows SmartScreen
  - Critical system drivers and essential OS services
- **Privilege Separation**: Administrator elevation is requested only for machine-level operations (`HKLM`). Standard user actions (`HKCU`) run safely under standard privileges.

---

## System Requirements

- **Operating System**: Windows 10 or Windows 11 (64-bit and ARM64 supported).
- **PowerShell Version**: Windows PowerShell 5.1 or PowerShell Core 7.x.
- **Privilege Level**: Standard user for current-user inspection and management; elevated administrator for machine-level operations (`HKLM`) and restore-point creation.

---

## Installation & Usage

### 1. Clone the Repository
```powershell
git clone https://github.com/nadeemhaaju143/windows-ultimate-manager.git
cd windows-ultimate-manager
```

### 2. Inspect the Script
Inspect `src/Windows-Safe-Manager.ps1` in your preferred editor or text viewer.

### 3. Run the Prototype
Open PowerShell in the project directory and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\src\Windows-Safe-Manager.ps1
```

> The execution-policy bypass applies only to the current PowerShell process session and does not alter system-wide security settings.

---

## Development & Automated Testing

Windows Ultimate Manager enforces automated testing and static analysis on all pull requests and commits.

### Run Automated Tests (Pester)
```powershell
Set-ExecutionPolicy -Scope Process Bypass
Import-Module Pester -MinimumVersion 5.0.0
Invoke-Pester -Path .\tests -Output Detailed
```

### Run Code Quality Analysis (PSScriptAnalyzer)
```powershell
Import-Module PSScriptAnalyzer
Invoke-ScriptAnalyzer -Path . -Settings .\PSScriptAnalyzerSettings.psd1 -Recurse
```

For more details on test structure, mock isolation, and test cases, see [tests/README.md](tests/README.md).

---

## Community & Contributing

We welcome community contributions, bug reports, and compatibility findings!

- **Report a Bug**: Use our [Bug Report Template](.github/ISSUE_TEMPLATE/bug_report.md).
- **Suggest a Feature**: Use our [Feature Request Template](.github/ISSUE_TEMPLATE/feature_request.md).
- **Submit Compatibility Results**: Report your Windows build test results using the [Compatibility Report Template](.github/ISSUE_TEMPLATE/compatibility_report.md).
- **Submit Code**: Read [CONTRIBUTING.md](CONTRIBUTING.md) and fill out the [Pull Request Template](.github/PULL_REQUEST_TEMPLATE.md).

---

## Project Authorship & Attribution

- **Initiator & Creator**: **Nadeem**, owner of **NH Digital**
- **Website**: [https://nhdigital.shop](https://nhdigital.shop)
- **Tagline**: *"Built by NH Digital. Improved by the community."*

---

## Disclaimer

This software is provided "as is", without warranty of any kind, express or implied. In no event shall the authors or copyright holders be liable for any claim, damages, or other liability. Review and test before executing. See [LICENSE](LICENSE).
