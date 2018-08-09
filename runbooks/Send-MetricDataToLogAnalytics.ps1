<# v0.1.0
.SYNOPSIS 
Register all VMs in a resource group or a single Virtual Machine to an OMS Log Analtyics workspace.

.DESCRIPTION
This runbook will register all VMs in a provided resource group to a specified OMS Log Analytics workspace if desired.
Specify the VMName parameter to only register a single Virtual Machine to an OMS Log Analytics workspace.

.PARAMETER ResourceGroupName
Specify the name of the resource group in which the VM(s) exists.

.PARAMETER VMName
Optionally specify the name of a single VM for which the Metric Performance data will be forwarded to Log Analytics.

.PARAMETER OMSWorkspaceName
Provide the name of the OMS Log Analytics workspace to which the VM(s) will forward metric data.

.PARAMETER OMSSubscriptionName
Optionally provide the name of the subscription in which the OMS Log Analytics workspace exists.  This is needed
if the OMS subscription is different from the VM subscription.
#>

param
(
    [Parameter(Mandatory)]
    [String]
    $ResourceGroupName,

    [Parameter()]
    [String]
    $VMName,

    [Parameter(Mandatory)]
    [String]
    $OMSWorkspaceName,

    [Parameter()]
    [String]
    $OMSResourceGroupName = $vm[0].ResourceGroupName,

    [Parameter()]
    [String]
    $OMSSubscriptionName
)

Import-Module AzureRm.Insights -RequiredVersion '4.0.2'

$conn = Get-AutomationConnection -Name AzureRunAsConnection
$account = Add-AzureRMAccount -ServicePrincipal -Tenant $conn.TenantID -ApplicationID $conn.ApplicationID -CertificateThumbprint $conn.CertificateThumbprint -EnvironmentName AzureUSGovernment

if ($VMName)
{
    $vms = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName
    $vmsStatus = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName -Status
    if ($vmsStatus.Statuses[1].DisplayStatus -eq 'VM running') { $onVms = $vms }
    else { $offVMs = $vms }
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
    $params = @{
        VM = $onVms
        OMSWorkspaceName = $OMSWorkspaceName
        OMSResourceGroupName = $OMSResourceGroupName
    }
    if ($OMSSubscriptionName) 
    {
        $params.Add('OMSSubscriptionName', $OMSSubscriptionName) 
    }
    else
    {
        $params.Add('OMSSubscriptionName', (Get-AzureRmContext).Subscription.Name)
    }

    Set-MetricForwardingToOMS @params 
}
else 
{
    Write-Output "No VMs found that are powered on"    
}