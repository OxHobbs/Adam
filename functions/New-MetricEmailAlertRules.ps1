<#
.SYNOPSIS

.DESCRIPTION

.PARAMETER VM

.EXAMPLE

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
            $existingAlerts = Get-AzureRmAlertRule -ResourceGroupName $vm.ResourceGroupName -TargetResourceId $vm.Id
            if ($existingAlerts.Name -contains $alertName)
            {
                Write-Verbose "Alert ($alertName) already exists for $($vm.Name), moving on out"
                continue
            }
            Write-Verbose "The Alert ($alertName) does not exist for the VM ($($vm.Name)) so I reckon I'll create it"
            
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