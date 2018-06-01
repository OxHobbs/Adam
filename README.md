# IAM Module ReadMe

## Description

This module contains a collection of tools that are used to aid in management of the IAM environment.  Semantic versioning is used in this project and a lite changelog is kept towards the bottom of this readme file.

Normal PowerShell commands may be used to interact with this module. Install this module from your NuGet server or copy the module to the following directory
`%ProgramFiles%/WindowsPowerShell/Modules`

To view all cmdlets available in this module run the following:

```powershell
Import-Module IAM
Get-Command -Module IAM
```
You may also use the help functionality with the cmdlets...

```powershell
Import-Module IAM
Get-Help Register-VMToOMS -Full
```

__note:__ This document gives an overview of changes that are made within releases
for a detailed view of what changes have happened within the module, refer
to the source code repository in the VCS.

### v0.4.0

* Implemented the external cmdlets: Set-MetricForwardingToOMS and New-MetricEmailAlertRules

### v0.3.0

* Fixed an issue where an empty folder in the module causes failures on importing. 

### v0.2.0

* Added the ability to specify which subscription the VMs and LA workspace exists.

### v0.1.0

* Initial implementation
