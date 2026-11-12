# Roadmap

> **Windows Ultimate Manager** — *"Built by NH Digital. Improved by the community."*  
> Initiated by **Nadeem** ([https://nhdigital.shop](https://nhdigital.shop))

All items below represent project milestones. Items marked `[x]` are implemented and tested; unchecked items are proposals under development.

---

## Completed Milestones
- [x] Initial conservative PowerShell prototype (`src/Windows-Safe-Manager.ps1`).
- [x] Document current capabilities, limitations, and safety recommendations.
- [x] GitHub community infrastructure (Issue templates for bugs, features, and compatibility reports).
- [x] Pull request template with safety, risk assessment, and test checklists.
- [x] PSScriptAnalyzer static analysis integration with custom rule settings.
- [x] Pester automated unit and integration test suite (`tests/Unit`, `tests/Integration`).
- [x] GitHub Actions automated Windows CI testing workflow (`powershell-tests.yml`).
- [x] Improved privilege detection, robust error handling, and modularized backup/restore engine.

---

## Planned & Next Milestones
- [ ] Test prototype on clean Windows 10 and Windows 11 virtual machines.
- [ ] Add structured backup/restore manifests for all future system configuration items.
- [ ] Add read-only scheduled-task inventory and inspector.
- [ ] Add installed-application inventory with verified, safe uninstall guidance.
- [ ] Add real-time CPU, RAM, and background process performance metrics.
- [ ] Add graphical user interface (GUI) only after all underlying core modules are validated.
- [ ] Add cryptographically signed release packages and automated checksum verification.
