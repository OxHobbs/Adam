Function Get-TimeAggregationType
{
    param($TimeAggregation)

    # Average, Minimum, Maximum, Total, Last
    $map = @{
        0 = ''
        3 = 'Average'
    }

    $map.$TimeAggregation
}
