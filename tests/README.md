# Windows Ultimate Manager - Test Suite

This directory contains the automated test suites for **Windows Ultimate Manager**.

The testing framework is built on [Pester](https://github.com/pester/pester) (PowerShell testing framework) and adheres to strict safety and isolation standards.

---

## Safety Principles

1. **Zero System Modification**: Automated tests must never alter the actual host machine's Windows configuration, registry, services, or files.
2. **Mocking & Isolation**: All registry access (`Get-ItemProperty`, `New-ItemProperty`, `Remove-ItemProperty`, `Test-Path`, `New-Item`), CIM queries (`Get-CimInstance`), and administrative checks (`Test-Admin`) are mocked or executed against temporary test drives (`TestDrive:`).
3. **Safe Integration Tests**: Integration tests verify environment compatibility, read-only system queries, and safe failure modes. No destructive operations are ever run in automated CI pipelines.

---

## Directory Structure

```text
tests/
├── README.md                      # This documentation
├── Unit/                          # Fast, fully-mocked isolated unit tests
│   └── StartupManager.Tests.ps1   # Unit tests for startup management, backup & restore
└── Integration/                   # Non-destructive environment & compatibility tests
    └── Compatibility.Tests.ps1    # Verification of read-only queries and OS detection
```

---

## Test Coverage

### Unit Tests (`tests/Unit/StartupManager.Tests.ps1`)
- **Startup Inventory**: Verifies querying startup entries via CIM without errors.
- **Registry Entry Identification**: Validates enumeration of classic Run locations across Current User and Machine scopes.
- **Backup Logic**: Verifies Base64 encoding of target registry paths and value names, and storage in the dedicated backup key.
- **Disable Operation**: Confirms that entries are backed up before removal, and that removal fails safely if backup fails.
- **Restore Operation**: Tests decoding of backed up values, restoration to original registry locations, and removal from the backup store.
- **Invalid User Input**: Tests handling of non-numeric selections, out-of-range indices, and cancelled operations.
- **Permission Handling**: Verifies that machine-level modifications require administrator privileges and fail gracefully when unprivileged.
- **Error Handling**: Verifies resilience when registry keys are locked, missing, or corrupt.
- **Corrupted Backup Data**: Validates that malformed or non-Base64 entries in the backup key do not crash the restore process.

### Integration Tests (`tests/Integration/Compatibility.Tests.ps1`)
- **PowerShell Compatibility**: Checks compatibility with Windows PowerShell 5.1 and modern PowerShell versions.
- **Read-Only Service Review**: Confirms that service review queries execute without modifying service states.
- **System Report Generation**: Tests generation of diagnostic reports in isolated temporary directories.
- **Execution Policy & Elevation Detection**: Tests non-invasive administrator and security policy detection.

---

## Running Tests Locally

### 1. Prerequisites
Ensure Pester (v5.0+) and PSScriptAnalyzer are installed:

```powershell
# In an elevated PowerShell prompt:
Install-Module -Name Pester -MinimumVersion 5.0.0 -Scope CurrentUser -Force -SkipPublisherCheck
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force -SkipPublisherCheck
```

### 2. Run All Tests
From the repository root:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
Invoke-Pester -Path .\tests -Output Detailed
```

### 3. Run Unit Tests Only
```powershell
Invoke-Pester -Path .\tests\Unit -Output Detailed
```

### 4. Run Code Quality Analysis (PSScriptAnalyzer)
```powershell
Invoke-ScriptAnalyzer -Path .\src, .\tests -Recurse
```
