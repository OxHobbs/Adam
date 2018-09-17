Function New-TempXMLConfig
{
    [CmdletBinding()]

    Param
    (
        [Parameter(Mandatory=$true)]
        [string]$VmId,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Windows', 'Linux')]
        [string]$OsType
    )
    
    $Path = (Join-Path -Path $PsScriptRoot -ChildPath '..\config')
    $xmlConfigPath = $null

    switch ($OsType) {
        "Windows" {$xmlConfigPath = Join-Path $Path "winDiagConfig.xml"}
        "Linux" {$xmlConfigPath = Join-Path $Path "linuxDiagConfig.xml"} 
    }

    $xmlConfig = [xml](Get-Content $xmlConfigPath)

    Write-Verbose "Writing the VM ID into the XML ($vmId)"
    $xmlConfig.WadCfg.DiagnosticMonitorConfiguration.Metrics.SetAttribute("resourceId", $VmId)
    $tmpPath = [System.IO.Path]::GetTempFileName()
    $xmlConfig.Save($tmpPath)

    return $tmpPath
}