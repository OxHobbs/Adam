Function Set-Context
{
    [CmdletBinding()]

    param
    (
        [Parameter(Mandatory)]
        [String]
        $SubscriptionName,

        [Parameter()]
        [String]
        $Reason
    )

    $currentContext = Get-AzureRmContext
    $switchedContext = $false
    Write-Verbose "Current subscription context: $($currentContext.Subscription.Name)"

    if ($currentContext.Subscription.Name -ne $SubscriptionName)
    {
        Write-Verbose "Switching subscription context to $($SubscriptionName) $Reason"        
        $sub = Get-AzureRmSubscription -SubscriptionName $SubscriptionName
        $null = Select-AzureRmSubscription -SubscriptionObject $sub -ErrorAction Stop
        $switchedContext = $true
    }

    return $switchedContext
}
