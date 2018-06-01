Function Import-AlertsJson
{
    param
    (
        [Parameter(Position=0)]
        [String] $ConfigFile = 'alert_rules.json'
    )

    begin
    {
        if (!$ConfigFile.toLower().EndsWith('.json')) 
        { 
            Write-Debug "Adding JSON file extension to $ConfigFile"
            $ConfigFile = $ConfigFile + ".json" 
        }
    }

    process
    {
        $moduleRoot = (Join-Path -Path $PsScriptRoot -ChildPath '..') 
        Write-Debug "Module Root is $moduleRoot"

        
        $path = ("$moduleRoot\config\$ConfigFile" | Resolve-Path -ErrorAction SilentlyContinue).Path
        if (-not $path) { throw 'Could not resolve path to the config file. Verify that it exists.'}

        try 
        {    
            $obj = Get-Content -Path $path | ConvertFrom-Json -ErrorAction Stop
            return $obj
        }
        catch 
        {
            Write-Error "There was an error importing and converting the file: $path"
        }
    }
}