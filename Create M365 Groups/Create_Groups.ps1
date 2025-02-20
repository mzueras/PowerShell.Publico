# Import the required modules
$psmodules= @("Microsoft.Graph", "Microsoft.Graph.Groups")
foreach ($module In $psmodules) {
    
    if (Get-Module -ListAvailable -Name $module) {
        Write-Host $module "está instalado y será importado."
        Import-Module $module
        Start-Sleep -Seconds 5
    } 
    else {
        Write-Host $module "No está instalado. Se instalará y después será importado."
        Install-Module  $module -Scope CurrentUser -Force
        Import-Module $module
    }
   
}

# Define the path to the CSV file
$csvPath = "C:\docker\Microsoft365\O365_Groups_List.txt"

# Read the CSV file
$groups = Import-Csv -Path $csvPath

# Function to create a Microsoft 365 group
function New-M365Group {
    param (
        [string]$DisplayName,
        [string]$MailNickname,
        [string]$Description,
        [string]$Owners,
        [string]$Members
    )

    # Create the group
    Write-Host "Creating group: $DisplayName" -ForegroundColor Green
    $group = New-MgGroup -DisplayName $DisplayName -MailNickname $MailNickname -Description $Description -GroupTypes "Unified" -MailEnabled:$true -SecurityEnabled:$false
    $groupID = $group.Id

    
    # Add owners to the group
    Write-Host "Adding owners to the group:$DisplayName " -ForegroundColor Green
    $ownersList = $Owners -split ";"
    foreach ($owner in $ownersList) {
        $ownerID = Get-MgUser -ConsistencyLevel eventual -Count userCount -Search "UserPrincipalName:$owner" | Select-Object -ExpandProperty Id
        New-MgGroupOwner -GroupId $groupID -DirectoryObjectId $ownerID
    }

    # Add members to the group
    Write-Host "Adding member to the group:$DisplayName " -ForegroundColor Green
    $membersList = $Members -split ";"
    foreach ($member in $membersList) {
        Write-Host $member
        $memberID = Get-MgUser -ConsistencyLevel eventual -Count userCount -Search "UserPrincipalName:$member" | Select-Object -ExpandProperty Id
        New-MgGroupMember -GroupId $groupID -DirectoryObjectId $memberID
    } 

    # Remove the user who is running the script from the group
    Write-Host "RemoveMe from the group:$DisplayName " -ForegroundColor Blue   
    $userContext = Get-MgContext | Select-Object -ExpandProperty Account
    $removeME = Get-MgUser -ConsistencyLevel eventual -Count userCount -Search "UserPrincipalName:$userContext" | Select-Object -ExpandProperty Id 
    Remove-MgGroupOwnerByRef -GroupId $groupID -DirectoryObjectId $removeME
}

# Loop through each row in the CSV and create the group
foreach ($group in $groups) {
    New-M365Group -DisplayName $group.DisplayName -MailNickname $group.MailNickname -Description $group.Description -Owners $group.Owners -Members $group.Members
}
