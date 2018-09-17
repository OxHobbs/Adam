function Enable-AdvancedMetrics
{
    [CmdletBinding()]

    param
    (
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine[]]
        $VM,

        [Parameter(Mandatory)]
        [String]
        $StorageAccountName,

        [Parameter()]
        [String]
        $StorageAccountResourceGroup = $VM.ResourceGroupName,

        [Parameter(Mandatory)]
        [ValidateSet('Windows', 'Linux')]
        [String]
        $OSType,

        [Parameter()]
        [Switch]
        $Force
    )

    Begin {}

    Process
    {
        foreach ($v in $vm)
        {
            $StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $StorageAccountResourceGroup -Name $StorageAccountName)[0].value

            if ($OSType -eq 'Windows')
            {
                $CfgPath = Join-Path -Path $PsScriptRoot -ChildPath '..\config\winDiagConfig.json'
                $diag = Get-AzureRmVMDiagnosticsExtension -ResourceGroupName $v.ResourceGroupName -VMName $v.Name

                if ($diag)
                {
                    if ($Force)
                    {
                        Write-Verbose "Force flagged - so the VM will be reconfigured"
                    }
                    else
                    {
                        Write-Output "$($v.Name) - VM is already configured, skipping"
                        continue
                    }
                }

                Write-Verbose "$($v.Name) -> Enabling Advanced Metrics"
                Set-AzureRmVMDiagnosticsExtension -ResourceGroupName $v.ResourceGroupName -VMName $v.Name -DiagnosticsConfigurationPath $CfgPath `
                    -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

            }
            elseif ($OSType -eq 'Linux')
            {
                $CfgPath = New-TempXmlConfig -VmId $v.VmId -OsType $OSType
                $content = Get-Content($CfgPath)
                $xmlCfg = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))

                $publicSetting = @{
                    StorageAccount = $StorageAccountName
                    xmlCfg = $xmlCfg
                }

                $privateSettings = @{
                    storageAccountName = $StorageAccountName
                    storageAccountKey = $StorageAccountkey
                }

                $extensionName = 'LinuxDiagnostic'
                $extension = $v.Extensions | Where-Object {$_.VirtualMachineExtensionType -eq "LinuxDiagnostic"}

                if ($extension)
                {
                    if ($Force)
                    {
                        Write-Verbose "Force flagged - so the VM will be reconfigured"
                    }
                    else
                    {
                        Write-Output "$($v.Name) - VM is already configured, skipping"
                        continue
                    }
                }
                else
                {
                    $extensionName = "LinuxDiagnostic"
                }

                Write-Verbose "$($v.Name) -> Enabling Advanced Metrics"
                Set-AzureRmVMExtension -ResourceGroupName $v.ResourceGroupName -VMName $v.Name -Publisher "Microsoft.OSTCExtensions" `
                    -ExtensionType "LinuxDiagnostic" -Name $extensionName -Location $v.Location -Settings $publicSetting `
                    -ProtectedSettings $privateSettings -TypeHandlerVersion '2.3'

                $vmBootConfig = Set-AzureRmVMBootDiagnostics -VM $v -Enable -StorageAccountName $StorageAccountName -ResourceGroupName $StorageAccountResourceGroup
                Update-AzureRmVM -VM $vmBootConfig -ResourceGroupName $v.ResourceGroupName
            }
        }

    }

    End {}
}
