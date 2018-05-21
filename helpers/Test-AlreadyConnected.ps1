Function Test-AlreadyConnected
{
    [CmdletBinding()]

    param($VM)

    if (-not $vm.Extensions) { return $false }

    $omsExtensions = $vm.Extensions | Where VirtualMachineExtensionType -match 'MicrosoftMonitoringAgent|OmsAgentForLinux'
    if (-not $omsExtensions) { return $false }
    if (-not $omsExtensions.ProvisioningState -eq 'Succeeded') { return $false }

    return $true
}