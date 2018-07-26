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

$hook = ConvertFrom-Json -InputObject $webhookData.RequestBody
$body = ConvertFrom-Json -InputObject $hook.RequestBody

# $storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $StorageAccountResourceGroup -Name $StorageAccountName

$tables = $body.SearchResult.tables

if ($tables)
{
    # Write-Output $tables
    Write-Verbose "Found tables"
}
else
{
    Write-Output "tables is empty"
    $body.SearchResult
    $body.SearchResult.tables
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

$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $StorageAccountResourceGroup -Name $StorageAccountName).Context
$storTable = Get-AzureStorageTable -Name $TableName -Context $saContext -ErrorAction SilentlyContinue


if (-not $storTable)
{
    $storTable = New-AzureStorageTable -Name $TableName -Context $saContext
}

Write-Output "Will write data to table $($storTable.Name)"


foreach ($o in $formattedObject)
{
    [Hashtable] $tableFields = @{}
    $objectNoteProps = (Get-Member -InputObject $o | Where MemberType -eq 'NoteProperty').Name

    foreach ($noteProp in $objectNoteProps)
    {
        if (-not $o.$noteProp)
        {
            $tableFields.Add($noteProp, 'Null')
        }
        else
        {
            $tableFields.Add($noteProp, $o.$noteProp)
        }
    }

    Write-Output "$storTable would be populate with these fields`n--------------------------"
    $tableFields
    Add-StorageTableRow -table $storTable `
        -partitionKey $PartitionKey `
        -rowKey ([guid]::NewGuid().tostring()) `
        -property $tableFields
}
#endregion