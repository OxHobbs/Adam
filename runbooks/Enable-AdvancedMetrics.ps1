<# v1.1.1
.SYNOPSIS
This runbook will enable guest-level 'advanced' metrics on a specified list of VMs.

.DESCRIPTION
This runbook will enable guest-level 'advanced' metrics for a specified list of VMs.  This runbook makes use
of the AzureMon Module.

If you provide a Resource Group and you DO NOT provide a VM Name then all VMs in the given resource group will have
advanced metrics enabled.

.PARAMETER ResourceGroupName
Specify the name of the resource group in which the VM(s) exists.

.PARAMETER VMNames
Optionally specify the name of a single or multiple VM(s) for which advanced metrics will be enabled.  If this
is not specified then all VMs in the given resource group will be grabbed.

.PARAMETER StorageAccountName
The name of the storage account in which the VMs will store advanced metrics

.PARAMETER StorageAccountResourceGroup
[Optional] The name of the resource group in which the storage account resides.  If left blank, the VM Resource Group will be used.

.PARAMETER SubscriptionName
[Optional] Specify the name of the subscription in which the VMs exist.

.PARAMETER Force
[Optional] Enabled enforcement if you want to overwrite existing settings for the Diagnostic Extension.
#>

param
(
    [Parameter(Mandatory)]
    [String]
    $ResourceGroupName,

    [Parameter(Mandatory)]
    [String]
    $StorageAccountName,

    [Parameter()]
    [String]
    $StorageAccountResourceGroup,

    [Parameter()]
    [String[]]
    $VMNames,

    [Parameter()]
    [String]
    $SubscriptionName,

    [Parameter()]
    [Bool]
    $Force = $False
)

$conn = Get-AutomationConnection -Name AzureRunAsConnection
$null = Add-AzureRMAccount -ServicePrincipal -Tenant $conn.TenantID -ApplicationID $conn.ApplicationID -CertificateThumbprint $conn.CertificateThumbprint -EnvironmentName AzureUSGovernment

Import-Module AzureMon -MinimumVersion '2.2.1'

if (-not $StorageAccountResourceGroup)
{
    $StorageAccountResourceGroup = $ResourceGroupName
}

if ($SubscriptionName)
{
    $sub = Get-AzureRmSubscription -SubscriptionName $SubscriptionName
    Select-AzureRmSubscription -SubscriptionObject $sub
}

$onVMs = @()
$offVMs = @()

if ($VMNames)
{
    foreach ($vmName in $VMNames)
    {
        Write-Verbose "Grabbing $vmName"

        try
        {
            $vm = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName
            $vmsStatus = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName -Status
            if ($vmsStatus.Statuses[1].DisplayStatus -eq 'VM running') { $onVms += $vm }
            else { $offVMs += $vm }
        }
        catch
        {
            Write-Error "Error grabbing VM - $vmName"
            Write-Error $_.Exception.ToString()
            continue
        }
    }
}
else
{
    $vms = Get-AzureRmVm -ResourceGroupName $ResourceGroupName
    $vmsRunning = (Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Status | Where-Object PowerState -eq 'VM running').Name
    $offVMs = $vms | Where-Object Name -NotIn $vmsRunning
    $onVms = $vms | Where-Object Name -In $vmsRunning
}

foreach ($offVM in $offVMs)
{
    Write-Warning "Virtual Machine: $($offVM.Name) will be skipped because it is not powered on"
}

if ($onVms)
{
    $onWindowsVMs = $onVms | Where-Object { (Get-OSType -VM $_) -eq 'Windows' }
    $onLinuxVMs = $onVms | Where-Object { (Get-OSType -VM $_) -eq 'Linux' }

    $params = @{
        StorageAccountName          = $StorageAccountName
        StorageAccountResourceGroup = $StorageAccountResourceGroup
    }

    if ($SubscriptionName) { $params['SubscriptionName'] = $SubscriptionName }
    if ($Force) { $params['Force'] = $true }

    if ($onWindowsVMs)
    {
        $params['OSType'] = 'Windows'
        $params['VM'] = $onWindowsVMs

        Enable-AdvancedMetrics @params
    }

    if ($onLinuxVMs)
    {
        $params['OSType'] = 'Linux'
        $params['VM'] = $onLinuxVMs

        Enable-AdvancedMetrics @params
    }
}
else
{
    Write-Output "No VMs found that are powered on"
}
