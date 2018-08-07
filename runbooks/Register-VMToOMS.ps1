<# v0.2.0
.SYNOPSIS 
Register all VMs in a resource group or a single Virtual Machine to an OMS Log Analtyics workspace.

.DESCRIPTION
This runbook will register all VMs in a provided resource group to a specified OMS Log Analytics workspace if desired.
Specify the VMName parameter to only register a single Virtual Machine to an OMS Log Analytics workspace.

.PARAMETER VMResourceGroupName
Specify the name of the resource group in which the VM exists.

.PARAMETER VMName
Optionally specify the name of a single VM which should be registered to the Log Analtyics workspace.

.PARAMETER OMSWorkspaceName
Provide the name of the OMS Log Analytics workspace to which the VM(s) will be registered

.PARAMETER VMSubscriptionName
Optionally provide the name of the subscription in which the VM exists if it is different from the
Automation Account Service Principal default subscription.

.PARAMETER OMSSubscriptionName
Optionally provide the name of the subscription in which the OMS Log Analytics workspace exists.  This is needed
if the OMS subscription is different from the VM subscription.
#>

param
(
    [Parameter(Mandatory)]
    [String]
    $VMResourceGroup,

    [Parameter()]
    [String]
    $VMName,

    [Parameter(Mandatory)]
    [String]
    $OMSWorkspaceName,

    [Parameter(Mandatory)]
    [String]
    $OMSResourceGroupName,

    [Parameter()]
    [String]
    $VMSubscriptionName,

    [Parameter()]
    [String]
    $OMSSubscriptionName
)


$conn = Get-AutomationConnection -Name AzureRunAsConnection
$account = Add-AzureRMAccount -ServicePrincipal -Tenant $conn.TenantID -ApplicationID $conn.ApplicationID -CertificateThumbprint $conn.CertificateThumbprint -EnvironmentName AzureUSGovernment

$vms = if ($VMName)
{
    Get-AzureRmVM -ResourceGroupName $VMResourceGroup -Name $VMName
}
else
{
    Get-AzureRmVM -ResourceGroupName $VMResourceGroup
}
 

$props = @{
    VM                   = $vms
    OMSWorkspaceName     = $OMSWorkspaceName
    OMSResourceGroupName = $OMSResourceGroupName
}

if ($VMSubscriptionName) { $props.Add('VMSubscriptionName', $VMSubscriptionName) }
if ($OMSSubscriptionName) { $props.Add('OMSSubscriptionName', $OMSSubscriptionName) }

Register-VMToOMS @props
