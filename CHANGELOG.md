# Changelog

All notable changes to **Windows Ultimate Manager** are documented in this file.

## [Unreleased] - Development Infrastructure & Testing Improvements

### Added
- **GitHub Community Infrastructure**:
  - Bug Report Issue Template (`.github/ISSUE_TEMPLATE/bug_report.md`) with sensitive log warnings.
  - Feature Request Issue Template (`.github/ISSUE_TEMPLATE/feature_request.md`) with privilege and safety checklists.
  - Compatibility Report Issue Template (`.github/ISSUE_TEMPLATE/compatibility_report.md`) for Windows 10/11 build testing.
  - Pull Request Template (`.github/PULL_REQUEST_TEMPLATE.md`) with test checklists and rollback strategies.
- **Automated Testing Suite (Pester 5)**:
  - Unit tests (`tests/Unit/StartupManager.Tests.ps1`) covering startup inventory, Run entry backup/restore, input validation, corrupted backup handling, and elevation checks.
  - Integration tests (`tests/Integration/Compatibility.Tests.ps1`) verifying non-destructive read-only inspection, OS detection, system report generation, and safety policy enforcement.
  - Test documentation (`tests/README.md`) outlining testing architecture and safety guidelines.
- **Code Quality & Static Analysis**:
  - PSScriptAnalyzer integration with custom ruleset (`PSScriptAnalyzerSettings.psd1`).
  - Documented technical justification for interactive CLI `Write-Host` console menu usage.
- **Continuous Integration (CI)**:
  - GitHub Actions workflow (`.github/workflows/powershell-tests.yml`) running static analysis and Pester tests on Windows runners.
  - Minimal read permissions and pinned action commit SHAs.

### Improved
- **PowerShell Script Modularization & Safety (`src/Windows-Safe-Manager.ps1`)**:
  - Added dot-source guard to allow importing functions for testing without automatically launching the interactive console menu.
  - Factored out modular functions: `Get-RunStartupEntry`, `Backup-RunEntry`, `Remove-RunStartupEntry`, `Restore-SingleRunEntry`.
  - Added approved PowerShell verb and singular noun naming with backwards-compatible aliases.
  - Added resilient exception handling for WMI/CIM queries and isolated environments.
  - Handled invalid/corrupted Base64 backup keys during restore operations without crashing.
  - Ensured directory initialization happens safely without unhandled errors.
- **Project Documentation**:
  - Updated `README.md`, `CONTRIBUTING.md`, and `ROADMAP.md` with complete NH Digital branding, official website links, safety guardrails, and development guidelines.
