Function Get-OperatorType
{
    param ($OperatorProperty)
    # $map = @{
    #     0 = 'GreaterThan'
    #     1 = 'GreaterThanOrEqual'
    #     2 = 'LessThan'
    #     3 = 'LessThanOrEqual'
    # }

    # # GreaterThan, GreaterThanOrEqual, LessThan, LessThanOrEqual
    # $map.$OperatorProperty
    [Enum]::Parse([Microsoft.Azure.Management.Monitor.Management.Models.ConditionOperator], $OperatorProperty)
}