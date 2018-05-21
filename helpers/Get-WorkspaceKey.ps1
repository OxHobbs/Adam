Function Get-WorkspaceKey
{
    [CmdletBinding()]

    param
    (
        [Parameter(Mandatory)]
        [String]
        $WorkspaceName,

        [Parameter(Mandatory)]
        [String]
        $ResourceGroupName,

        [Parameter(Mandatory)]
        [String]
        $SubscriptionName
    )

    $currentContext = Get-AzureRmContext
    $switchedContext = $false
    Write-Verbose "Current subscription context: $($currentContext.Subscription.Name)"

    if ($currentContext.Subscription.Name -ne $SubscriptionName)
    {
        Write-Verbose "Switching subscription context to $($SubscriptionName) to get workspace key"        
        $sub = Get-AzureRmSubscription -SubscriptionName $SubscriptionName
        $null = Select-AzureRmSubscription -SubscriptionObject $sub
        $switchedContext = $true
    }

    $key = (Get-AzureRmOperationalInsightsWorkspaceSharedKeys -ResourceGroupName $ResourceGroupName -Name $WorkspaceName).PrimarySharedKey

    if ($switchedContext)
    {
        Write-Verbose "Switching subscription context back to $($currentContext.Subscription.Name)"        
        $null = Select-AzureRmSubscription -SubscriptionObject $currentContext.Subscription
    }

    return $key
}