<#
.SYNOPSIS

.DESCRIPTION

.PARAMETER VM

.PARAMETER OMSWorkspaceName

.PARAMETER OMSResourceGroupName

.PARAMETER OMSSubscriptionName

.EXAMPLE

#>
Function Set-MetricForwardingToOMS
{
    [CmdletBinding(SupportsShouldProcess = $true)]

    param
    (
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine[]]
        $VM,

        [Parameter(Mandatory)]
        [String]
        $OMSWorkspaceName,

        [Parameter()]
        [String]
        $OMSResourceGroupName = $vm[0].ResourceGroupName,

        [Parameter()]
        [String]
        $OMSSubscriptionName
    )

    Begin
    {
        $alerts = Import-AlertsJson

        try
        {
            $currentContext = Get-AzureRmContext
            $contextChanged = Set-Context -SubscriptionName $OMSSubscriptionName -Reason "to obtain OMS workspace"

            $workspace = Get-AzureRmOperationalInsightsWorkspace -ResourceGroupName $OMSResourceGroupName -Name $OMSWorkspaceName -ErrorAction Stop           

            if ($contextChanged)
            {
                Set-Context -SubscriptionName $currentContext.SubscriptionName -Reason "switching context back to original state"
            }
        }
        catch
        {
            Write-Verbose "There was an issue getting the workspace"
            Write-Error $_.Exception.toString()
            break
        }
    }

    Process
    {
        Write-Verbose "There are $($alerts.Count) Alerts that will be enabled to send data to the log analytics workspace ($($workspace.Name))"        
        foreach ($v in $vm)
        {
            Write-Verbose "Virtual Machine -> $($v.Name)"
            foreach ($alert in $alerts)
            {
                Write-Verbose "Working on alert -> $($alert.Name)"

                try
                {
                    $realAlert = Get-AzureRmAlertRule -TargetResourceId $v.Id -ResourceGroupName $v.ResourceGroupName | 
                        Where-Object { $_.AlertRuleResourceName.Contains($alert.Name) }
                    
                    if (-not $realAlert)
                    {
                        Write-Verbose "Unable to find an alert on VM [$($v.Name)] that matches the alert [$($alert.Name)], skipping"
                        continue
                    }

                    Write-Verbose "Found alert [$($realAlert.AlertRuleResourceName)] on VM [$($v.Name)]"

                    $diag = Get-AzureRmDiagnosticSetting -ResourceId $v.Id

                    if ($diag.WorkspaceId -eq $workspace.ResourceId)
                    {
                        Write-Verbose "The VM [$($v.Name)] is already configured to forward metric data Log Analytics [$($workspace.Name)], skip a doodle do"
                        continue
                    }

                    if ($PSCmdlet.ShouldProcess($v.Name, "Configure forwarding to log analytics for alert [$($realAlert.AlertRuleResourceName)]"))
                    {
                        Set-AzureRmDiagnosticSetting -ResourceId $v.Id -WorkspaceId $workspace.ResourceId -Enabled $true -RetentionEnabled $true -RetentionInDays 30 -ErrorAction Stop
                        Write-Verbose "Completed log analytics forwarding for the alert [$($realAlert.AlertRuleResourceName)] on VM [$($v.Name)]"
                    }
                }
                catch
                {
                    Write-Error "Error occured setting up log analytics forwarding for the alert [$($realAlert.AlertRuleResourceName)] on VM [$($v.Name)]"                
                    Write-Error $_.Exception.ToString()
                }
            }            
        }
    }

    End {}
}