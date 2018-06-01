Function Get-TimeAggregationType
{
    param($TimeAggregation)

    # Average, Minimum, Maximum, Total, Last
    # $map = @{
    #     0 = 'Average'
    #     1 = 'Minimum'
    #     2 = 'Maximum'
    #     3 = 'Total'
    #     4 = 'Last'
    # }

    # $map.$TimeAggregation
    [Enum]::Parse([Microsoft.Azure.Management.Monitor.Management.Models.TimeAggregationOperator], $TimeAggregation)
}
