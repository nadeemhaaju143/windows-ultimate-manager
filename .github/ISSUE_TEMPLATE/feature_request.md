---
name: Feature Request
about: Suggest an idea or enhancement for Windows Ultimate Manager
title: "[FEATURE] "
labels: ["enhancement"]
assignees: ''
---

### Proposed Feature
A clear and concise description of the proposed feature.

### Problem It Solves
What problem or pain point does this feature address? (e.g., "Currently, users cannot...")

### Expected Behaviour
Describe how the feature should behave from the user's perspective.

### Suggested Implementation
- Detail any PowerShell cmdlets, CIM classes, or Windows APIs you propose using.
- Explain whether the feature should be read-only or make modifications.
- Note: All modifications must be reversible and require explicit user confirmation.

### Potential Risks & Stability Impact
- What are the potential failure modes?
- Could this impact Windows stability, background performance, or other applications?
- Does this interact with any critical Windows components?

### Permissions Required
- [ ] Operates under standard user privileges
- [ ] Requires elevated administrator privileges (explain why elevation is genuinely required)

### Safety Checklist
- [ ] Does NOT disable Microsoft Defender, Windows Firewall, SmartScreen, or Windows Update
- [ ] Does NOT modify or disable critical Windows services or drivers
- [ ] Does NOT apply bulk or undocumented registry tweaks
- [ ] Provides a clean rollback or restore mechanism
