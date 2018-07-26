param
(
    [Object]
    $WebhookData,

    [String]
    $StorageAccountName
)

$WebhookData

if (-not $webhookData.RequestBody)
{
    $webhook = $WebhookData | ConvertFrom-JSON
    Write-output $webhook
}

$body = ConvertFrom-Json -InputObject $webhookData.RequestBody
# Write-Output $body
$tables = $body.SearchResult.tables

Write-Output $tables

$formattedObject = @()

# for ($c, $tables.columns.name, $c++)
# {

# }

$colNames = $tables.columns.name
$props = @{}

for ($row = 0; $row -lt $tables.rows.Count; $row++)
{
    Write-host "Looking at row $row"
    $props = @{}

    for ($col = 0; $col -lt $colNames.Count; $col++)
    {
        Write-Host "looking at col $col, row $row"
        Write-Host "Column Name: $($colNames[$col])"
        # $props = [Ordered]@{
        $props[$colNames[$col]] = $tables.rows[$row][$col]
    }

    $formattedObject += New-Object -TypeName PSObject -Property $props
}

Write-Output "`n`n------------------------------------`n"
Write-Output $formattedObject