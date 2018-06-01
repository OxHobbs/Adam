Function New-MetricEmailAlertRules
{
    [CmdletBinding(SupportsShouldProcess = $true)]

    param
    (
        [Parameter(Mandatory)]
        [String]
        $ResourceGroupName,

        [Parameter(Mandatory)]
        $VM,

        [Parameter(Mandatory)]
        [String[]]
        $EmailAdresses
    )

    $Alerts = Import-AlertsJson
    $Alerts = $Alerts | Where-Object { $_.Actions -contains 'Microsoft.Azure.Management.Monitor.Management.Models.RuleEmailAction' }

    foreach ($alert in $Alerts)
    {
        $actionEmail = New-AzureRmAlertRuleEmail -CustomEmail $EmailAddresses

        $params = @{
            Location                = $alert.Location
            ResourceGroupName       = $ResourceGroupName
            Name                    = $alert.Name
            WindowSize              = $alert.Condition.WindowSize
            Operator                = (Get-OperatorType -OperatorProperty $alert.Condition.OperatorProperty)
            Threshold               = $alert.Condition.Threshold
            TimeAggregationOperator = (Get-TimeAggregationType -TimeAggregation $alert.Condition.TimeAggregation)
            MetricName              = $alert.Condition.DataSource.MetricName
            Action                  = $actionEmail
        }

        if ($alert.Description) { $params['Description'] = $alert.Description }

        if ($PSCmdlet.ShouldProcess($vm.Name, "Create email metric alert"))
        {
            Add-AzureRmMetricAlertRule @params
        }
    }

}