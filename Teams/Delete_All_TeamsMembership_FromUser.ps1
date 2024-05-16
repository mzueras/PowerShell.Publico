<#

    .SYNOPSIS
      Obtiene los grupos en los que el usuario es miembro y lo quita de Teams.

      TE QUITA DE TODOS LOS GRUPOS DE TEAMS A LOS QUE PERTENECES!!!!!!!!!!!
      
      Requiere tener instalado el módulo de Teams.
      Instalar con Install-Module -Name MicrosoftTeams
    
    .DESCRIPTION
      Util para quitar un usuario que está en demasiados grupos o que se ha añadido de forma erronea a los mismos.
    
    .NOTES
    Puede que la eliminación de un error tipo:
    Remove-TeamUser : Last owner cannot be removed from the team
    Es normal, el ultimo owner no puede ser eliminado.
    
    .URL
    https://learn.microsoft.com/en-us/powershell/module/teams/get-teamuser
    https://learn.microsoft.com/en-us/powershell/module/teams/remove-teamuser

#>

# Introducir el nombre del usuario en formato nombre.apellido@dominio.com
$username = "name@domain.com"

# Conectar a Teams.
Connect-MicrosoftTeams

# Ejecutar el bucle por cada uno de los Teams a los que el usuario ha sido añadido.
$teams = Get-Team -User $username
foreach ($team in $teams){
  try {
    Remove-TeamUser -GroupId $team.GroupId -User $username
    Write-Host "Usuario $username eliminado del grupo $team.DisplayName" -ForegroundColor Green
  }
  catch {
    Write-Host "Error al eliminar el usuario $username del grupo" $team.DisplayName -ForegroundColor Red
    Write-Host $Error[0].Exception.Message -ForegroundColor Red
  }
  
}
