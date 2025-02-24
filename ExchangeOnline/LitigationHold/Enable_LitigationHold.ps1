<#
    .DESCRIPTION
    Activar LitigationHold en todos los buzones de correo de la organización 
    que tengan la capacidad de BPOS_S_Enterprise y que no tengan activado el LitigationHold.

    .COMPONENT
    Exchange Online Management Shell

    .NOTES
    Para poder activar el LitigationHold en un buzón de correo, es necesario que el buzón de correo tenga la capacidad de BPOS_S_Enterprise.
    Esta capacidad se asigna a los buzones de correo de los usuarios que tienen una licencia de Office 365 E3 o E5.

    .LINK
    https://learn.microsoft.com/en-us/purview/ediscovery-create-a-litigation-hold
    
#>

# Conectar a Exchange Online
Connect-ExchangeOnline

# Obtener todos los buzones de correo de la organización que no tengan activado el LitigationHold
$users = Get-Mailbox -ResultSize unlimited | Where-Object {$_.LitigationHoldEnabled -match "False" -and $_.RecipientTypeDetails -eq "UserMailbox" -and $_.PersistedCapabilities -like "BPOS_S_Enterprise"}

# Activar el LitigationHold en los buzones de correo
Write-Host "Buzones sin LitigationHold: " $users.Count
$users | ForEach-Object {
    Set-Mailbox -Identity $_.Alias -LitigationHoldEnabled $true
    Write-Host "LitigationHold activado para: " $_.Alias
}

# Desconectar de Exchange Online
Disconnect-ExchangeOnline
