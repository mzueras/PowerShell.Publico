<#
    .SYNOPSIS
        Install & Import PS Modules.

    .PARAMETER $psmodules
        Install required modules.
    
    .NOTES
        Run as admin.
#>


$psmodules= @("PowerShellGet", "ExchangeOnlineManagement", "Microsoft.Graph")
foreach ($module In $psmodules) {
    
    if (Get-Module -ListAvailable -Name $module) {
        Write-Host $module "It is installed and will be imported."
        Import-Module $module
        Start-Sleep -Seconds 5
    } 
    else {
        Write-Host $module "It is not installed. It will be installed and then imported."
        Install-Module  $module
        Import-Module $module
    }
   
}