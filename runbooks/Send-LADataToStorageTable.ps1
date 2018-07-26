param
(
    $WebhookData
)

$webhook = ConvertFrom-JSON -InputObject $WebhookData
$body = ConvertFrom-Json -InputObject $webhook.RequestBody
$tables = ConvertFrom-Json -InputObject $body.SearchResult.tables

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








param(
      # The table to pull rows from
        [Parameter(Mandatory=$true,
        ValueFromPipelineByPropertyName=$true)]
        [string]
        $TableName="StorageTable1",

        # The account that contains the storage table
        [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true)]
        [string]
        $StorageAccountName="",

        # The account's key
        [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true)]
        [string]
        $StorageAccountKey="",

        [string]
        $input

    )

write-output $input

function InsertRow($table, [String]$partitionKey, [String]$rowKey, [int]$intValue)
{
    $entity = New-Object "Microsoft.WindowsAzure.Storage.Table.DynamicTableEntity" $partitionKey, $rowKey
    $entity.Properties.Add("IntValue", $intValue)
    $result = $table.CloudTable.Execute([Microsoft.WindowsAzure.Storage.Table.TableOperation]::Insert($entity))
}

        if(!$AzureStorageContext)
        {
            #No storage context provided, define the storage context.
            $AzureStorageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
        }

        # Get a reference to a table.
        $table = Get-AzureStorageTable -Name $TableName -Context $AzureStorageContext

        for ($p = 1; $p -le 10; $p++)
        {
        for ($r = 1; $r -le 10; $r++)
        {
            InsertRow $table "P$p" "R$r" $r
        }
        }
        # Create a table query.
        $query = New-Object Microsoft.WindowsAzure.Storage.Table.TableQuery

        # Set query filter string
        $query.FilterString = $Filter
        
        if($SelectedColumns)
        {
            # Select only the provided columns
            $query.SelectColumns = $SelectedColumns
        }

        if($First)
        {
            # Take only the first X items
            $query.TakeCount = $First
        }

        Write-Verbose "Retrieving $First entities from $TableName with filter '$Filter' and select columns '$SelectedColumns'"

		# Initalize the continuation token
        $continuationToken = $null

        #region Execute query in a segmented fashion so later functions in the pipeline can get their work started while the query continues
        do
        {
            # Execute the query
            $result = $table.CloudTable.ExecuteQuerySegmented($query, $continuationToken, $null, $null)

            # Save the returned continuation token
            $continuationToken = $result.ContinuationToken

            $entities = $result.Results

            if($First)
            {
                # Reduce the number of entities to take by the number of entities retrieved
                $numEntities = $entities.Count
                $First -= $numEntities

                Write-Verbose "Entities retrieved $numEntities, entities left to retrieve $First"
                if($First -gt 0)
                {
                    # Set the new take count
                    $query.TakeCount = $First
                }
                else
                {
                    # No more entities to take, drop the continuation token
                    $continuationToken = $null
                }
            }

            if($DoNotExpandProperties)
            {
                # Property expansion not requested, just output each entity
                foreach ($entity in $entities)
                {
                    Write-Output $entity
                }
            }
            else
            {
                # Property expansion requested, expand the properties into a flat PSCustom object
                foreach ($entity in $entities)
                {
                    $expandedEntity = @{}
                    $expandedEntity["PartitionKey"] = $entity.PartitionKey
                    $expandedEntity["RowKey"] = $entity.RowKey
                    $expandedEntity["Timestamp"] = $entity.Timestamp
                    $expandedEntity["ETag"] = $entity.ETag
                
                    foreach ($property in $entity.Properties)
                    {
                        foreach($key in $property.Keys)
                        {
                            $expandedEntity[$key] = $property[$key].PropertyAsObject
                        }
                    }

                    $psObject = [PSCustomObject]$expandedEntity
                    Write-Output $psObject
                }                
            }
        }
        while ($continuationToken -ne $null) # Continue until there's no continuation token provided
