function Get-OSType($VM)
{
    if ($vm.OSProfile.WindowsConfiguration) { Write-Verbose "VM is Windows"; return 'windows' }
    elseif ($vm.OSProfile.LinuxConfiguration) { Write-Verbose "VM is linux"; return 'linux' }
}