# Windows Ultimate Manager

**A free, open-source Windows optimization and maintenance toolkit.**

Created and initiated by **Nadeem**, owner of **NH Digital**.

Website: https://nhdigital.shop

> **Project status: Early prototype. Not yet a stable public release.**
>
> The current PowerShell utility is a conservative starting point. Review the code before running it. Test in a virtual machine or on a non-critical PC first. Do not run scripts from the internet without inspecting them.

## Mission

Help Windows users understand and manage startup applications, inspect services, review system configuration, and make cautious, reversible changes wherever technically possible.

## Current prototype

The included script currently provides:
- Startup inventory.
- Reversible disabling and restoration of classic Run-key startup entries.
- Read-only Windows service review.
- System report export.
- Restore-point creation attempt and recovery instructions.
- Safety recommendations and activity logging.

It does **not** yet implement a complete optimizer, graphical interface, scheduled-task manager, debloater, privacy manager, or full rollback system. Those are planned only after testing and review.

## Safety first

- Read the complete script before running it.
- Back up important personal files.
- Create a restore point, but do not treat it as a substitute for a backup.
- Test changes on a virtual machine or spare PC first.
- Never disable Defender, Firewall, SmartScreen, Windows Update, UAC, drivers, or critical services based on generic debloat advice.
- The tool does not guarantee that every change can be reversed by System Restore.
- Use administrator privileges only when an operation genuinely requires them.

## Requirements

- Windows 10 or Windows 11.
- Windows PowerShell 5.1 or later.
- Some operations require an elevated PowerShell session.

## Run the prototype

Open PowerShell in the project folder and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\src\Windows-Safe-Manager.ps1
```

The execution-policy change applies only to the current PowerShell process. Inspect the script first and run only if you understand and trust it.

## Project authorship

This project was initiated by **Nadeem**, owner of **NH Digital**. It is published as an open-source project so developers, Windows enthusiasts, security researchers, and users can inspect the source, report issues, suggest improvements, and contribute changes.

Community contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## Disclaimer

This project is provided "as is", without warranty of any kind. You are responsible for reviewing and deciding whether to run any operation on your computer. See [LICENSE](LICENSE).

## Roadmap

See [ROADMAP.md](ROADMAP.md) for planned work. Roadmap items are proposals, not promises or completed features.
