<#
.SYNOPSIS
Send data about certificates stored in Azure Key Vault to a custom Log Analytics table.

.DESCRIPTION
This cmdlet will send data about Certificates stored in Azure Key Vault to a custom Log Analytics table.  Tags that are 
provided in the 'ValidTags' parameter will also be sent to Log Analytics.  The Certificates that are collected may be
pulled from a provided Threshold.  By default, all certificate data is collected and forwarded.

.PARAMETER VaultResourceGroup
Provide the resource group in which the Azure Key Vault exists.

.PARAMETER VaultName
Provide the name of the Azure Key Vault

.PARAMETER VaultSubscriptionName
Provide the name of the subscription in which the Azure Key Vault exists.  This can be ommited if the subscription is already in the
correct context.

.PARAMETER LogAnalyticsWorkspaceName
Provide the name of the Log Analytics workspace to which the data will be forwarded.

.PARAMETER LogAnalyticsSubscriptionName
Specify the name of the subscription in which the Log Analytics workspace exists.  This may be ommitted if the subscription is already in
the current context.

.PARAMETER ExpirationThresholdDays
Specify a threshold in days to which the certificate expiration date will be compared.  If the expiration date falls within this threshold, 
then the data about those certificates will be forwarded to Log Analytics.  A 'falsey' value will forward all certificate metadata.

.PARAMETER ValidTags
Provide a list of tags that should be forwarded to Log Analytics.  If a specified valid tag is found on the certificate, the value of that tag
is sent to Log Analytics.  Tags that aren't specified as Valid Tags will not be forwarded.

.EXAMPLE
This exmaple shows how to pull data about certificates from the 'django-keyvault' to the 'webapp-workspace.'  Because of the threshold set to 90 days, only certificates
expiring within the next 90 days will be forwarded to Log Analytics.

Send-KVCertInfo -VaultResourceGroup django -VaultName django-keyvault -LogAnalyticsWorkspaceName webapp-workspace -Verbose -LogAnalyticsResourceGroup django-webapps -ExpirationThresholdDays 90
#>
function Send-KVCertInfoToLA
{
    [CmdletBinding()]

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

    $currentSub = (Get-AzureRmContext).Subscription.Name

    if (-not $VaultSubscriptionName)
    {
        $VaultSubscriptionName = $currentSub
    }

    if (-not $LogAnalyticsSubscriptionName)
    {
        $LogAnalyticsSubscriptionName = $currentSub
    }

    if ($currentSub -ne $VaultSubscriptionName)
    {
        Set-Context -SubscriptionName $VaultSubscriptionName -Reason "to access KeyVault in $VaultSubscriptionName"
    }

    $certificates = Get-AzureKeyVaultCertificate -VaultName $VaultName
    $certCollection = @()

    if (-not $certificates)
    {
        Write-Warning "No Certificates found in vault ($VaultName)"
        break
    }

    Write-Verbose "Found $($certificates.Count) certificates in Vault ($VaultName)"

    $Workspace = Get-Workspace -Name $LogAnalyticsWorkspaceName -ResourceGroupName $LogAnalyticsResourceGroup -SubscriptionName $LogAnalyticsSubscriptionName
    Write-Verbose "Found the workspace -> $($Workspace.Name)"

    $WorkspaceKey = Get-WorkspaceKey -WorkspaceName $LogAnalyticsWorkspaceName -ResourceGroupName $LogAnalyticsResourceGroup -SubscriptionName $LogAnalyticsSubscriptionName
    Write-Verbose "Found the workspace key"

    Set-Context -SubscriptionName $VaultSubscriptionName -Reason "set to Vault Sub to get certificate data"
    $ExtractDate = Get-Date -Format "yyyyMMdd hh:mm:ss"

    foreach ($certificate in $certificates)
    {
        $cert = Get-AzureKeyVaultCertificate -VaultName $certificate.VaultName -Name $certificate.Name

        if (-not (Test-WithinThreshold -Certificate $cert.Certificate -ThresholdDays $ExpirationThresholdDays))
        {
            Write-Verbose "Ceritifcate ($($cert.Name)) is not within the $ExpirationThresholdDays threshold, skipping"
            continue
        }

        $ExpireDate = (Get-Date $cert.Certificate.GetExpirationDateString() -Format "yyyy-MM-ddTHH:MM:ssK").ToString()

        $certProps = [Ordered]@{
            ExtractDate = $ExtractDate
            HostName    = $null
            Alias       = $null
            Subject     = $cert.Certificate.Subject
            Issuer      = $cert.Certificate.Issuer
            Serial      = $cert.Certificate.SerialNumber
            ValidFrom   = $cert.Certificate.GetEffectiveDateString()
            Expiry      = $cert.Certificate.GetExpirationDateString()
            ExpireDate  = $ExpireDate
        }

        foreach ($ValidTag in $ValidTags)
        {
            if ($cert.Tags.Keys -contains $ValidTag)
            {
                Write-Verbose "Adding valid tag ($ValidTag : $($cert.Tags.$ValidTag)) to the payload"
                $certProps[$ValidTag] = $cert.Tags.$ValidTag
            }
            else
            {
                Write-Verbose "$ValidTag was specified as a valid tag; however, the certificate $($cert.Name) was not tagged.  Will return Null for this field"
                $certProps[$ValidTag] = $null
            }
        }

        $certCollection += New-Object -TypeName PSObject -Property $certProps
    }

    $certCollectionJSON = ConvertTo-Json -InputObject $certCollection -Depth 10

    $IngestionParams = @{
        customerId      = $Workspace.CustomerId
        sharedKey       = $WorkspaceKey
        body            = $certCollectionJSON
        logType         = "CertificateMetadata"
        timestampField  = 'Timestamp'
        EnvironmentName = 'AzureUSGovernment'
    }

    $status = Send-OMSAPIIngestionFile @IngestionParams
    Write-Verbose "OMSIngestion Status: $status"

    $certCollection
}
