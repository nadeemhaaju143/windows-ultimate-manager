---
name: Compatibility Report
about: Report compatibility results for a specific Windows build or environment
title: "[COMPAT] "
labels: ["compatibility"]
assignees: ''
---

### Test Environment
- **Operating System**: [ ] Windows 10 / [ ] Windows 11
- **OS Edition**: (e.g., Home, Pro, Enterprise, Education)
- **OS Build Number**: (Run `[System.Environment]::OSVersion.Version` or `winver`)
- **System Architecture**: [ ] x64 / [ ] ARM64 / [ ] x86
- **PowerShell Version**: (Run `$PSVersionTable.PSVersion` e.g., 5.1.22621.3880 or 7.4.x)
- **Environment Type**: [ ] Physical Hardware / [ ] Virtual Machine (Hyper-V / VMware / VirtualBox)
- **Privilege Level**: [ ] Standard User / [ ] Elevated Administrator

### Hardware Context (where relevant)
- **Device Model / CPU**: 
- **RAM**: 
- **Storage Type**: (e.g., NVMe SSD, SATA SSD, HDD)

### Features Tested
Check all that apply:
- [ ] Option 1: Create a System Restore point
- [ ] Option 2: View startup apps (Win32_StartupCommand inventory)
- [ ] Option 3: Disable one classic startup entry (Run key backup & removal)
- [ ] Option 4: Restore startup entries disabled by this tool
- [ ] Option 5: Review Windows services (read-only Out-GridView / table)
- [ ] Option 6: Export system report (ProgramData report generation)
- [ ] Option 7: Show safe recommendations
- [ ] Option 8: Show how to use System Restore

### Test Result
- **Overall Status**: [ ] Pass (All tested features functioned as expected) / [ ] Partial (Some features worked, others had issues) / [ ] Fail (Critical failure or error)

### Issues Encountered & Detailed Findings
Describe any unexpected behavior, console errors, or performance issues during testing:
```text
Paste any relevant output or error messages here
```

### Additional Notes
Any tips or specific observations for this Windows build or hardware configuration.
