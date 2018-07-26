param
(
    [Object]
    $WebhookData,

    [Parameter(Mandatory)]
    [String]
    $StorageAccountName,

    [Parameter(Mandatory)]
    [String]
    $StorageAccountResourceGroup,

    [Parameter()]
    [String]
    $StorageAccountSubscriptionName,

    [Parameter()]
    [String]
    $TableName,

    [Parameter()]
    [String]
    $PartitionKey
)

$conn = Get-AutomationConnection -Name AzureRunAsConnection
$account = Add-AzureRMAccount -ServicePrincipal -Tenant $conn.TenantID -ApplicationID $conn.ApplicationID -CertificateThumbprint $conn.CertificateThumbprint -EnvironmentName AzureUSGovernment

#region process webhook
$Body = ConvertFrom-JSON -InputObject $WebhookData.RequestBody
$tables = $body.SearchResult.tables

if (-not $tables)
{
    Write-Output "tables is empty, exiting"
    $body.SearchResult
    $body.SearchResult.tables
    exit
}

$formattedObject = @()

$colNames = $tables.columns.name
$props = @{}

for ($row = 0; $row -lt $tables.rows.Count; $row++)
{
    Write-Verbose "Looking at row $row"
    $props = @{}

    for ($col = 0; $col -lt $colNames.Count; $col++)
    {
        Write-Verbose "looking at col $col, row $row"
        Write-Verbose "Column Name: $($colNames[$col])"
        $props[$colNames[$col]] = $tables.rows[$row][$col]
    }

    $formattedObject += New-Object -TypeName PSObject -Property $props
}

$formattedObject
#endregion

#region Storage Table
if ((Get-AzureRmContext).Subscription.Name -ne $StorageAccountSubscriptionName)
{
    $null = Select-AzureRmSubscription -Subscription $StorageAccountSubscriptionName
}

$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $StorageAccountResourceGroup -Name $StorageAccountName).Context
$storTable = Get-AzureStorageTable -Name $TableName -Context $saContext -ErrorAction SilentlyContinue


if (-not $storTable)
{
    $storTable = New-AzureStorageTable -Name $TableName -Context $saContext
}

Write-Verbose "Will write data to table $($storTable.Name)"

foreach ($o in $formattedObject)
{
    [Hashtable] $tableFields = @{}
    $objectNoteProps = (Get-Member -InputObject $o | Where MemberType -eq 'NoteProperty').Name

    foreach ($noteProp in $objectNoteProps)
    {
        if ($o.$noteProp)
        {
            $tableFields.Add($noteProp, $o.$noteProp)
        }
        else
        {
            $tableFields.Add($noteProp, '')
        }
    }

    $tableFields
    Add-StorageTableRow -table $storTable `
        -partitionKey $PartitionKey `
        -rowKey ([guid]::NewGuid().tostring()) `
        -property $tableFields
}
#endregion