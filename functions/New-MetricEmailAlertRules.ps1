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
        $VM,

        [Parameter(Mandatory)]
        [ValidateSet('Windows', 'Linux')]
        [String]
        $OSType,

        [Parameter()]
        [String]
        $SubscriptionName
    )

    Begin
    {
        Write-Verbose "OS Selected - $OSType"
        $Alerts = if ($OSType -eq 'Windows')
        {
            Import-AlertsJson -ConfigFile 'alerts_windows.json'
        }
        else
        {
            Import-AlertsJson -ConfigFile 'alerts_linux.json'
        }
        Write-Verbose "Found $($Alerts.Count) Alerts"

        if ($SubscriptionName)
        {
            $null = Set-Context -SubscriptionName $SubscriptionName -Reason "to pull a list of VMs"
        }
    }

    Process
    {
        foreach ($v in $vm)
        {
            foreach ($alert in $Alerts)
            {
                $alertName = "$($alert.Name)__$($v.Name)"
                $existingAlert = Get-AzureRmAlertRule -ResourceGroupName $v.ResourceGroupName -Name $alertName -ErrorAction SilentlyContinue

                if ($existingAlert)
                {
                    Write-Verbose "Alert ($alertName) already exists for $($v.Name), validating configuration of alert"

                    if (Test-AlertCompliant -CurrentAlert $existingAlert -DesiredAlert $alert)
                    {
                        Write-Verbose "Alert ($alertName) already exists for $($v.Name) and is configured correctly, moving on out"
                        continue
                    }
                    else 
                    {
                        Write-Verbose "The alert exists but is not currently configured correctly.  Reckon I'll continue..."    
                    }
                }
                else
                {
                    Write-Verbose "The Alert ($alertName) does not exist for the VM ($($v.Name)) so I reckon I'll create it"
                }

                
                $actionEmail = New-AzureRmAlertRuleEmail -CustomEmail $alert.Actions.CustomEmails
                $window = $alert.Condition.WindowSize
        
                $params = @{
                    Location                = $alert.Location
                    ResourceGroupName       = $v.ResourceGroupName
                    TargetResourceId        = $v.Id
                    Name                    = $alertName
                    WindowSize              = (New-TimeSpan -Days $window.Days -Minutes $window.Minutes -Seconds $window.Seconds -Hours $window.Hours)
                    Operator                = (Get-OperatorType -OperatorProperty $alert.Condition.OperatorProperty)
                    Threshold               = $alert.Condition.Threshold
                    TimeAggregationOperator = (Get-TimeAggregationType -TimeAggregation $alert.Condition.TimeAggregation)
                    MetricName              = $alert.Condition.DataSource.MetricName
                    Action                  = $actionEmail
                }

                if ($alert.Description) { $params['Description'] = $alert.Description }
        
                if ($PSCmdlet.ShouldProcess($v.Name, "Create email metric alert for metric ($($params['Name']))"))
                {
                    Add-AzureRmMetricAlertRule @params
                }
            }            
        }
    }

    End {}
}