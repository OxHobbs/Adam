Function Get-Workspace
{
    [CmdletBinding(SupportsShouldProcess = $false)]

    param
    (
        [Parameter(Mandatory)]
        [String]
        $Name,

        [Parameter(Mandatory)]
        [String]
        $ResourceGroupName,

        [Parameter(Mandatory)]
        [String]
        $SubscriptionName
    )

    $currentContext = Get-AzureRmContext
    $switchedContext = $false
    Write-Verbose "The current subscription context is $($currentContext.Subscription.Name)"

    if ($currentContext.Subscription.Name -ne $SubscriptionName)
    {
        Write-Verbose "Switching subscription context to $($SubscriptionName) to get workspace"
        $sub = Get-AzureRmSubscription -SubscriptionName $SubscriptionName
        $null = Select-AzureRmSubscription -SubscriptionObject $sub
        $switchedContext = $true
    }

    $workspace = Get-AzureRmOperationalInsightsWorkspace -Name $Name -ResourceGroupName $ResourceGroupName -ErrorAction Stop

    if ($switchedContext)
    {
        Write-Verbose "Switching subscription context back to $($currentContext.Subscription.Name)"
        $null = Select-AzureRmSubscription -SubscriptionObject $currentContext.Subscription
    }

    return $workspace
}