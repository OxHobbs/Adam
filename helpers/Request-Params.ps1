Function Request-Params
{
    param($VM, $Workspace, $WorkspaceKey)

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

    $osType = Get-OSType -VM $VM
    if ($osType -eq 'linux')
    {
        $params.ExtensionType = 'OmsAgentForLinux'
        $params.Publisher = 'Microsoft.EnterpriseCloud.Monitoring'
        $params.Name = 'OMS'
    }

    return $params
}