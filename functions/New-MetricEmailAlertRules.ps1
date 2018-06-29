<#
.SYNOPSIS
Create new Metric Alert rules on virtual machines based off exported alerts from an existing resource.

.DESCRIPTION
This cmdlet points to a JSON file in the config directory of the module and uses it to configure other virtual machines with like alerts.  It should
also provide some functonality to update existing alerts for key values; such as, Window Size, Threshold and Email addresses.

The cmdlet supports common parameters like -Verbose -WhatIf -Confirm etc.

.PARAMETER VM
A Virtual Machine object that is retrieved with Get-AzureRmVM.  This parameter takes these objects from the pipeline as well.  View examples
for more details.

.EXAMPLE
This example shows how to create metric alert rules on all VMs in a resource group named 'MyRG'

Get-AzureRmVM -ResourceGroupName MyRG | New-MetricEmailAlertRules -Verbose
#>
Function New-MetricEmailAlertRules
{
    [CmdletBinding(SupportsShouldProcess = $true)]

    param
    (
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine[]]
        $VM
    )

    Begin
    {
        $Alerts = Import-AlertsJson
    }

    Process
    {
        foreach ($alert in $Alerts)
        {
            $alertName = "$($alert.Name)__$($vm.Name)"
            $existingAlert = Get-AzureRmAlertRule -ResourceGroupName $vm.ResourceGroupName -Name $alertName -ErrorAction SilentlyContinue

            if ($existingAlert)
            {
                Write-Verbose "Alert ($alertName) already exists for $($vm.Name), validating configuration of alert"

                if (Test-AlertCompliant -CurrentAlert $existingAlert -DesiredAlert $alert)
                {
                    Write-Verbose "Alert ($alertName) already exists for $($vm.Name) and is configured correctly, moving on out"
                    continue
                }
                else 
                {
                    Write-Verbose "The alert exists but is not currently configured correctly.  Reckon I'll continue..."    
                }
            }
            else
            {
                Write-Verbose "The Alert ($alertName) does not exist for the VM ($($vm.Name)) so I reckon I'll create it"
            }

            
            $actionEmail = New-AzureRmAlertRuleEmail -CustomEmail $alert.Actions.CustomEmails
            $window = $alert.Condition.WindowSize
    
            $params = @{
                Location                = $alert.Location
                ResourceGroupName       = $vm.ResourceGroupName
                TargetResourceId        = $vm.Id
                Name                    = $alertName
                WindowSize              = (New-TimeSpan -Days $window.Days -Minutes $window.Minutes -Seconds $window.Seconds)
                Operator                = (Get-OperatorType -OperatorProperty $alert.Condition.OperatorProperty)
                Threshold               = $alert.Condition.Threshold
                TimeAggregationOperator = (Get-TimeAggregationType -TimeAggregation $alert.Condition.TimeAggregation)
                MetricName              = $alert.Condition.DataSource.MetricName
                Action                  = $actionEmail
            }
    
            if ($alert.Description) { $params['Description'] = $alert.Description }
    
            if ($PSCmdlet.ShouldProcess($vm.Name, "Create email metric alert for metric ($($params['Name']))"))
            {
                Add-AzureRmMetricAlertRule @params
            }
        }
    }

    End {}
}