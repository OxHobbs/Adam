function Test-WithinThreshold
{
    [CmdletBinding()]

    param
    (
        $Certificate,
        $ThresholdDays
    )

    if ($ThresholdDays)
    {
        Write-Verbose "Checking $($Certificate.GetExpirationDateString()) against threshold $ThresholdDays days"
        return ((Get-Date $Certificate.GetExpirationDateString()) - (Get-Date)).Days -le $ThresholdDays
    }

    return $true
}