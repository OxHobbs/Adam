function Test-AlertCompliant
{
    [CmdletBinding()]

    param
    (
        [Parameter(Mandatory)]
        $CurrentAlert,

        [Parameter(Mandatory)]
        $DesiredAlert
    )

    $results = @()
    $result = $CurrentAlert.Condition.OperatorProperty -eq (Get-OperatorType -OperatorProperty $DesiredAlert.Condition.OperatorProperty)
    Write-Verbose "Operator Property compliant: $result"
    $results += $result

    # There is an odd edge case here where the following expression evals to false even though the values are equal in debugger
    # $CurrentAlert.Condition.Threshold -eq $DesiredAlert.Condition.Threshold
    $val = $DesiredAlert.Condition.Threshold
    $result = $CurrentAlert.Condition.Threshold -eq $val
    Write-Verbose "Threshold compliant: $result"
    $results += $result

    $result = $CurrentAlert.Condition.TimeAggregation -eq (Get-TimeAggregationType -TimeAggregation $DesiredAlert.Condition.TimeAggregation)
    Write-Verbose "Time Aggregation compliant: $result"
    $results += $result

    $result = $CurrentAlert.Condition.WindowSize.TotalSeconds -eq $DesiredAlert.Condition.WindowSize.TotalSeconds
    Write-Verbose "Window Size compliant: $result"
    $results += $result

    $test = Compare-Object -ReferenceObject $CurrentAlert.Actions.CustomEmails -DifferenceObject $DesiredAlert.Actions.CustomEmails
    $result = [String]::IsNullOrEmpty($test)
    Write-Verbose "Email list compliant: $result"
    $results += $result

    return $false -notin $results
}