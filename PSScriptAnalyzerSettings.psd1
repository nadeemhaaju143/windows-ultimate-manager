# PSScriptAnalyzer Settings for Windows Ultimate Manager
@{
    # ExcludeRules with explicit technical justification:
    # PSAvoidUsingWriteHost is excluded because Windows-Safe-Manager.ps1 is an interactive CLI menu utility
    # that uses Write-Host deliberately for colored console menu display and user prompts without polluting
    # standard PowerShell pipeline objects.
    ExcludeRules = @(
        'PSAvoidUsingWriteHost'
    )

    # Include default security, defect, and style rules
    IncludeDefaultRules = $true
}
