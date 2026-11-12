# Contributing

Thank you for your interest in improving Windows Ultimate Manager.

## Before contributing
- Open an issue to discuss significant changes.
- Explain the Windows versions tested.
- Keep changes small and focused.
- Prefer read-only discovery before modification.
- Never introduce destructive defaults or silent system changes.

## Pull requests
Include:
1. What the change does and why.
2. Exact Windows versions tested.
3. Risk assessment and affected components.
4. Backup and rollback behaviour.
5. Test results and screenshots/logs where useful.

## Safety requirements
- No disabling security protections by default.
- No bulk disabling of Windows services.
- No registry cleaners or undocumented tweaks.
- Require explicit confirmation for system changes.
- Provide a rollback path or clearly explain why one is unavailable.
- Do not include credentials, personal data, or machine-specific logs.

All contributions are subject to maintainer review.
