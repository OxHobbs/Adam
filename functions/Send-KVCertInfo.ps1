function Send-KVCertInfo
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
        $VaultSubscriptionName = (Get-AzureRmContext).Subscription.Name,

        [Parameter(Mandatory)]
        [String]
        $LogAnalyticsWorkspaceName,

        [Parameter()]
        [String]
        $LogAnalyticsResourceGroup = $VaultResourceGroup,

        [Parameter()]
        [String]
        $LogAnalyticsSubscriptionName = $VaultSubscriptionName,

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

    Write-Host "JSON------------------------------------------JSON"
    $certCollectionJSON

    $IngestionParams = @{
        customerId      = $Workspace.CustomerId
        sharedKey       = $WorkspaceKey
        body            = $certCollectionJSON
        logType         = "CertificateMetadata"
        timestampField  = 'Timestamp'
        EnvironmentName = 'AzureUSGovernment'
    }

    Send-OMSAPIIngestionFile @IngestionParams
    $certCollection
}

# Send-KVCertInfo -VaultResourceGroup django -VaultName django-keyvault -LogAnalyticsWorkspaceName ox-workspace -Verbose -LogAnalyticsResourceGroup gov -ExpirationThresholdDays 90