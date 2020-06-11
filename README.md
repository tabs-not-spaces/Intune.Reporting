# Intune Configuration Capture & Reporting Solution

## Overview
Solution to extract segments of Intune configuration and provide pretty, formatted tables of configuration data for inclusion in a high level document.

Current endpoints that are captured:
- ADMX (GPO based Configuration Policies)
- AutoPilot
- Device Compliance
- Device Configuration
- Enrollment Status Page
- Scripts
- Win32 Applications

To be finalized:

- Endpoint Security Policies

## Usage

Only works with PowerShell 7 - using all the shiny new ternary and null check tools.

The **well-known application id** for intune (d1ddf0e4-d672-4dae-b554-9d5bdfd93547) will request consent using the MASL libraries.

Import the module from this repository (assuming you are already in the root of this directory)

``` PowerShell
Install-Module .\IntuneReporting
```

There's only one function publically exposed - because I'm nice like that.

``` PowerShell
Get-IntuneConfig -adminEmail user@clienttenant.com -tenantId clienttenant.com -outputFolder C:\path\to\store\generated\files
```

Raw JSON output from the Intune environment will be sent to the **outputFolder** directory.
A details report will be stored in the root of the **outputFolder** in markdown format - from this you can easily convert to word / pdf from VSCode.

Solution requires a GA account or at least Intune administrators - for obvious reasons.