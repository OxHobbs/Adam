Function Get-OperatorType
{
    param ($OperatorProperty)
    $map = @{
        0 = 'GreaterThan'
        2 = 'LessThan'
    }

    # GreaterThan, GreaterThanOrEqual, LessThan, LessThanOrEqual
    $map.$OperatorProperty
}