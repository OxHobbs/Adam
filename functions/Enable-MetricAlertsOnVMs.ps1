function Enable-MetricAlertsOnVMs
{
    [CmdletBinding(SupportsShouldProcess = $true)]

    param
    (
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine[]] 
        $VM
    )

    Begin
    {

    }

    Process
    {

    }

    End {}
}