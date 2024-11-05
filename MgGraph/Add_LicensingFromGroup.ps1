<#
    .DESCRIPTION
    Añade los usuarios del grupo a un SKU de licencia de Azure AD.
    Calcula las licencias disponibles y asigna las licencias a los usuarios del grupo.
    En caso de no haber suficientes licencias, muestra los usuarios que no tienen licencia asignada.
    Y detiene el proceso.

    .PARAMETER $grupoID
    Identificador del grupo en Azure AD.

    .PARAMETER $EmsSku
    Nombre del SKU de la licencia.
    Se puede obtener con Get-MgSubscribedSku -All | Select-Object SkuPartNumber

    .PARAMETER $usageLocation
    Ubicación de los usuarios. Requerido para asignar licencias. Ejemplo: ES

    .PARAMETER $ClientId
    Identificador de la aplicación en Azure AD.

    .PARAMETER $TenantId
    Identificador del inquilino de Azure AD.

    .PARAMETER $ClientSecret
    Secreto de la aplicación en Azure AD.

    .NOTES
    Requiere la instalacion del modulo Microsoft.Graph y se instala con: 
    Install-Module Microsoft.Graph -Scope CurrentUser -Repository PSGallery -Force

#>


# Grupo de usuarios que deben tener la licencia
$groupId = ""


# Configuration
$ClientId = ""
$TenantId = ""
$ClientSecret = ""

# SKu de licencia que se va a asignar
$skuName = "O365_BUSINESS_PREMIUM"

# Localización de los usuarios
$usageLocation = "ES"





# Convertir el secret en un objeto seguro
$ClientSecretPass = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force

# Crear la credencial
$ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientId, $ClientSecretPass

# Conectar a Azure AD mediante Graph
Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $ClientSecretCredential -NoWelcome
Get-MgContext | Select-Object Scopes



# Obtener los usuarios del grupo
$users = Get-MgGroupMember -GroupId $groupId -All
$EmsSku = Get-MgSubscribedSku -All | Where-Object SkuPartNumber -eq $skuName | Select-Object -Property Sku*, ConsumedUnits -ExpandProperty PrepaidUnits

# Obtener usuarios sin licencia y calcular las licencias libres.
$usuariosSinLicencia = @()

foreach ($user in $users) { # Buscar los usuarios que no tengan la licencia asignada.

    if (-not(Get-MgUserLicenseDetail -UserId $user.Id | Where-Object SkuId -eq $EmsSku.SkuId)) { # Si no tiene la licencia asignada, lo añade a la lista.
        
        $userData = Get-mguser -UserId $user.Id
        
        $usuariosSinLicencia += [PSCustomObject]@{
            Id = $userData.Id
            DisplayName = $userData.DisplayName
            UserPrincipalName = $userData.UserPrincipalName
        }

    }

}


# Licencias disponibles
if (($EmsSku.enabled - $EmsSku.consumedUnits) -le $usuariosSinLicencia.Count) { # Comprobar si hay suficientes licencias para asignar a todos los usuarios.

    $licenciasDisponibles = $EmsSku.enabled - $EmsSku.consumedUnits
    $usuariosSinDisponibilidad = $usuariosSinLicencia | Select-Object -Skip $licenciasDisponibles
    $usuariosSinLicencia = $usuariosSinLicencia | Select-Object -First $licenciasDisponibles
    
}

foreach ($user in $usuariosSinLicencia) { # Buscar los usuarios que no tengan la licencia asignada y asignarla.

    if ($null -eq (Get-MgUser -UserId $user.id -Property UsageLocation | Select-Object UsageLocation).value) { # Si no tiene la ubicación asignada, se asigna.
        Update-MgUser -UserId $user.Id -Usagelocation $usageLocation 
    }

    if (-not(Get-MgUserLicenseDetail -UserId $user.Id | Where-Object SkuId -eq $EmsSku.SkuId)) { # Si no tiene la licencia asignada, se asigna.
        Set-MgUserLicense -UserId $user.Id -AddLicenses @{SkuId = $EmsSku.SkuId} -RemoveLicenses @()
    }

}



if ($null -ne $usuariosSinDisponibilidad) { # Si hay usuarios sin licencia asignada, crea un log.
    
    # Ruta para guardar el log
    $path = "c:\LogsLicencias"
    if (-not(Test-Path -Path $path)) { # Si no existe la carpeta, la crea.
        New-Item -Path $path -ItemType Directory -
    }
    
    # Exporta los usuarios sin licencia a un archivo de texto.
    $usuariosSinDisponibilidad | Select-Object -Property DisplayName, UserPrincipalName | out-file -FilePath "$path\UsuariosSinLicencia_$fechaHoy.txt"

}


# Desconectar de Azure AD mediante Graph
Disconnect-MgGraph
