# Contributing to Windows Ultimate Manager

Thank you for your interest in improving **Windows Ultimate Manager**, a community-driven open-source project initiated by **Nadeem**, owner of **NH Digital** ([https://nhdigital.shop](https://nhdigital.shop)).

> **Tagline**: *"Built by NH Digital. Improved by the community."*

---

## Community Guidelines & Reporting

Before opening a pull request or issue, please review our contribution templates:

1. **Bug Reports**: Use the [Bug Report Template](.github/ISSUE_TEMPLATE/bug_report.md). Never share credentials, passwords, tokens, or sensitive system logs.
2. **Feature Requests**: Use the [Feature Request Template](.github/ISSUE_TEMPLATE/feature_request.md). Propose safe, reversible, well-documented changes.
3. **Compatibility Reports**: Use the [Compatibility Report Template](.github/ISSUE_TEMPLATE/compatibility_report.md) to report test results on specific Windows 10/11 builds.
4. **Pull Requests**: Every submission must follow the [Pull Request Template](.github/PULL_REQUEST_TEMPLATE.md).

---

## Safety Requirements & Non-Negotiable Guardrails

To protect user systems and maintain Windows stability, every contribution must adhere to these rules:

- **No Security Downgrades**: Never disable or weaken Microsoft Defender, Windows Firewall, SmartScreen, Windows Update, or User Account Control (UAC).
- **No Bulk Modifications**: No wholesale service disabling, component removal, or aggressive debloat scripts.
- **Explicit User Confirmation**: Any state-changing operation must prompt the user with clear context and require explicit confirmation.
- **Reversibility First**: All modifications must include an automated or structured rollback mechanism.
- **No Telemetry or Tracking**: The project does not collect data or phone home.
- **Documented Cmdlets Only**: Avoid undocumented registry keys, private APIs, or fragile system hacks.

---

## Development & Testing Workflow

### 1. Branching Strategy
- Do not submit unreviewed changes directly to `main`.
- Create a dedicated development feature branch:
  ```powershell
  git checkout -b feature/your-feature-name
  ```

### 2. Local Code Verification
Before submitting a pull request, you must execute the automated test suite and static analysis:

```powershell
# 1. Run PSScriptAnalyzer code quality check
Invoke-ScriptAnalyzer -Path . -Settings .\PSScriptAnalyzerSettings.psd1 -Recurse

# 2. Run Pester automated unit and integration tests
$config = [PesterConfiguration]::Default
$config.Run.Path = @(".\tests\Unit", ".\tests\Integration")
$config.TestRegistry.Enabled = $false
$config.Output.Verbosity = 'Detailed'
Invoke-Pester -Configuration $config
```

### 3. Writing Unit Tests
- New functions or changes to existing functions must include corresponding unit tests in `tests/Unit/`.
- Tests must **never** modify the running system's actual registry, services, or files.
- Use mocks (`Mock`) and isolated temporary drives (`TestDrive:`) for all write/delete operations.
- Destructive integration tests are strictly prohibited from automated CI runners.

### 4. Continuous Integration (CI)
All pull requests automatically trigger the GitHub Actions workflow (`.github/workflows/powershell-tests.yml`) on Windows runners. Your PR will only be merged if:
- PSScriptAnalyzer passes with zero critical errors.
- All Pester unit and integration tests pass.
- The PR template checklist is fully completed.

---

## Code Style & Standards

- Compatible with Windows PowerShell 5.1 and modern PowerShell Core (7.x).
- Use approved PowerShell verbs (`Get-Verb`).
- Use singular nouns for cmdlets and functions.
- Do not suppress analyzer warnings without documented justification.
- Keep functions modular, readable, and well-commented.

Thank you for helping make Windows Ultimate Manager safer and more reliable for everyone!
