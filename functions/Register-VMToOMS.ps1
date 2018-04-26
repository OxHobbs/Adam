<#
.SYNOPSIS
Register VMs to an OMS Workspace

.DESCRIPTION
This cmdlet will register a VM or collection of VMs passed via pipeline to a specified OMS workspace.

.PARAMETER VM
A VM object that will be registered to the OMS workspace.

.PARAMETER OMSWorkspaceName
The name of the OMS/Log Analytics workspace that the VM will be registered to.

.PARAMETER OMSResourceGroupName
The name of the resource group that the OMS workspace resides.

.EXAMPLE
This example shows collecting all VMs in a resource group called 'myRG' and registering them to an OMS workspace.

Get-AzureRmVM -ResourceGroupName 'myRG' | Register-VMToOMS -OMSWorkspaceName 'myOMSworkspace' -OMSResourceGroupName 'myRG'

.EXAMPLE 
This example shows retrieving a VM and then registering it.

$vm = Get-AzureRmVM -ResourceGroupName 'myRG' -Name 'Front-End-01'
Register-VMToOMS -VM $vm -OMSWorkspaceName 'myOMSWorkspace' -OMSResourceGroupName 'myRG'
#>

function Register-VMToOMS
{
    [CmdletBinding(SupportsShouldProcess = $true)]

    param
    (
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine[]] 
        $VM,

        [Parameter(Mandatory)]
        [String]
        $OMSWorkspaceName,

        [Parameter(Mandatory)]
        [String]
        $OMSResourceGroupName
    )

    Begin {}

    Process
    {
        function GetOSType($VM)
        {
            if ($vm.OSProfile.WindowsConfiguration) { Write-Verbose "VM is Windows"; return 'windows' }
            elseif ($vm.OSProfile.LinuxConfiguration) { Write-Verbose "VM is linux"; return 'linux' }
        }

        $workspace = Get-AzureRmOperationalInsightsWorkspace -Name $OMSWorkspaceName -ResourceGroupName $OMSResourceGroupName -ErrorAction Stop
        $key = (Get-AzureRmOperationalInsightsWorkspaceSharedKeys -ResourceGroupName $OMSResourceGroupName -Name $OMSWorkspaceName).PrimarySharedKey 

        $params = @{
            VMName = $vm.Name
            ResourceGroupName = $vm.ResourceGroupName
            Location = $vm.Location
            Name = 'MicrosoftMonitoringAgent'
            Publisher = 'Microsoft.EnterpriseCloud.Monitoring'
            ExtensionType = 'MicrosoftMonitoringAgent'
            TypeHandlerVersion = '1.0'
            SettingString = "{'workspaceId': '$($workspace.CustomerId.Guid)'}" 
            ProtectedSettingString = "{'workspaceKey': '$key'}"
        }

        $osType = GetOSType -VM $VM
        if ($osType -eq 'linux')
        {
            $params.ExtensionType = 'OmsAgentForLinux'
            $params.Publisher = 'Microsoft.EnterpriseCloud.Monitoring'
            $params.Name = 'OMS'
        }

        if ($PSCmdlet.ShouldProcess($vm.Name, "Register to OMS workspace, $($workspace.name)"))
        {
            $status = $null

            try
            {
                Write-Verbose "Registering VM, $($vm.Name), to the OMS Workspace, $($workspace.Name)"
                $res = Set-AzureRmVMExtension @params -ErrorAction Stop
                $res | Format-Table  @{Label="VMName"; Expression={ $vm.Name }}, @{Label="OMSWorkspace"; Expression={ $workspace.Name}}, IsSuccessStatusCode, StatusCode
                Write-Verbose "Registered VM to workspace successfully"
                $status = 'Success'
            }
            catch
            {
                Write-Verbose "Encountered an error registering the VM ($($vm.Name)) to OMS Workspace ($($workspace.Name))"
                Write-Error $PSItem.Exception.Message
                $status = 'Failed'
            }
        }
    }
    
    End {}
}