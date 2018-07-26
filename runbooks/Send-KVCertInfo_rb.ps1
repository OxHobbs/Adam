param
(
    [Parameter(Mandatory)]
    [String]
    $VaultResourceGroup,

    [Parameter(Mandatory)]
    [String]
    $VaultName,

    [Parameter()]
    [String]
    $VaultSubscriptionName,

    [Parameter(Mandatory)]
    [String]
    $LogAnalyticsWorkspaceName,

    [Parameter()]
    [String]
    $LogAnalyticsResourceGroup = $VaultResourceGroup,

    [Parameter()]
    [String]
    $LogAnalyticsSubscriptionName,

    [Parameter()]
    [Int]
    $ExpirationThresholdDays = 0,

    [Parameter()]
    [String[]]
    $ValidTags = @(
        'HostName',
        'Alias',
        'CertType'
    )
)

$conn = Get-AutomationConnection -Name AzureRunAsConnection
$account = Add-AzureRMAccount -ServicePrincipal -Tenant $conn.TenantID -ApplicationID $conn.ApplicationID -CertificateThumbprint $conn.CertificateThumbprint -EnvironmentName AzureUSGovernment

$currentSub = (Get-AzureRmContext).Subscription.Name

if (-not $VaultSubscriptionName)
{
    $VaultSubscriptionName = $currentSub
}

if (-not $LogAnalyticsSubscriptionName)
{
    $LogAnalyticsSubscriptionName = $currentSub
}

$params = @{
    VaultResourceGroup           = $VaultResourceGroup
    VaultName                    = $VaultName
    VaultSubscriptionName        = $VaultSubscriptionName
    LogAnalyticsWorkspaceName    = $LogAnalyticsWorkspaceName
    LogAnalyticsResourceGroup    = $LogAnalyticsResourceGroup
    LogAnalyticsSubscriptionName = $LogAnalyticsSubscriptionName
    ExpirationThresholdDays      = $ExpirationThresholdDays
    ValidTags                    = $ValidTags
}

Send-KVCertInfo @params
