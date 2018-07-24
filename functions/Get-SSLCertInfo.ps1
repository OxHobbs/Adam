<#
.SYNOPSIS
Get information about an SSL certificate of a given webite.

.DESCRIPTION
The cmdlet takes a list of URLs and will attempt to process through each one to gather information about the SSL cert provided.
It will return the Name, Issuer, Subject, Expiration Date and Effective Date for each reachable site/cert.

.PARAMETER UrlList
Provide a list of URLs for websites from which you want to obtain SSL certificate information.

.EXAMPLE
This example pulls the certificate information for three commonly known websites.

Get-SSLCertInfo -UrlList @('https://www.bing.com', 'https://www.google.com', 'https://twitter.com')

.EXAMPLE
This example pulls the same information as the previous example, but then outputs this data to a CSV file on the user's desktop.

Get-SSLCertInfo -UrlList @('https://www.bing.com', 'https://www.google.com', 'https://twitter.com') | Export-Csv -NoTypeInformation -Path ~/Desktop/SSLCertInfo.csv
#>

function Get-SSLCertInfo
{
    [CmdletBinding()]

    param
    (
        [Parameter(Mandatory)]
        [String[]]
        $UrlList
    )

    $certs = @()

    foreach ($url in $UrlList)
    {
        $request = [Net.WebRequest]::Create($url)
        Write-Verbose "$url -> $request"

        $response = $request.GetResponse()

        if ($response.StatusCode -ne 'OK')
        {
            Write-Warning "Unable to obtain a successful response from -> $url"
            continue
        }

        $certificate = $request.ServicePoint.Certificate

        $certProps = [Ordered]@{
            Name = $certificate.GetName()
            Issuer = $certificate.Issuer
            Subject = $certificate.Subject
            ExpirationDate = $certificate.GetExpirationDateString()
            EffectiveDate = $certificate.GetEffectiveDateString()
        }

        $certs += New-Object -TypeName PSObject -Property $certProps
    }

    $certs
}
