<# v1.0.0
.SYNOPSIS 
Create metric alerts for a given VM or set of VMs.

.DESCRIPTION
This runbook will create metric alerts for a VM or all VMs in a given resource group based off of a JSON file that
describes how the alerts should be set up.  The name of each alert must be unique; therefore, the name of the alerts 
when created follow a naming convention like the following:  AlertName__<serverName>

If you provide a Resource Group and you DO NOT provide a VM Name then all VMs in the given resource group will have
new metric alerts created.

.PARAMETER ResourceGroupName
Specify the name of the resource group in which the VM(s) exists.

.PARAMETER VMName
Optionally specify the name of a single VM for which to create Metric Alerts
#>

param
(
    [Parameter(Mandatory)]
    [String]
    $ResourceGroupName,

    [Parameter()]
    [String[]]
    $VMNames
)

$conn = Get-AutomationConnection -Name AzureRunAsConnection
$account = Add-AzureRMAccount -ServicePrincipal -Tenant $conn.TenantID -ApplicationID $conn.ApplicationID -CertificateThumbprint $conn.CertificateThumbprint -EnvironmentName AzureUSGovernment

Import-Module AzureMon -MinimumVersion '2.0.1'

$onVMs = @()
$offVMs = @()

if ($VMNames)
{
    foreach ($vmName in $VMNames)
    {
        Write-Verbose "Grabbing $vmName"
        $vm = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName
        $vmsStatus = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName -Status
        if ($vmsStatus.Statuses[1].DisplayStatus -eq 'VM running') { $onVms += $vm }
        else { $offVMs += $vm }
    }
}
else
{
    $vms = Get-AzureRmVm -ResourceGroupName $ResourceGroupName
    $vmsRunning = (Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Status | where PowerState -eq 'VM running').Name
    $offVMs = $vms | Where Name -NotIn $vmsRunning
    $onVms = $vms | Where Name -In $vmsRunning
}

foreach ($offVM in $offVMs)
{
    Write-Warning "Virtual Machine: $($offVM.Name) will be skipped because it is not powered on"
}

if ($onVms)
{
    $onWindowsVMs = $onVms | Where { (Get-OSType -VM $_) -eq 'Windows' }
    $onLinuxVMs = $onVms | Where { (Get-OSType -VM $_) -eq 'Linux' }
    if ($onWindowsVMs) { New-MetricEmailAlertRules -VM $onWindowsVMs -OSType Windows }
    if ($onLinuxVMs) { New-MetricEmailAlertRules -VM $onLinuxVMs -OSType Linux }
}
else 
{
    Write-Output "No VMs found that are powered on"    
}

