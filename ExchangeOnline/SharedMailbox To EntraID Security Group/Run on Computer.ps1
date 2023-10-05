<#
    .SYNOPSIS
        Sync user principal name from shared mailbox to security group.

    .DESCRIPTION
        Search all shared mailbox and gets UPN from Exchange Online.
        Adds (if not exist) the UPN to a security group on Entra ID.

    .PARAMETER $GroupId
        Group ID from security group on Entra ID with all shared mailboxes UPN.

#>

# Connect to Exchange and Graph
Connect-ExchangeOnline 
Connect-MgGraph

 
# ObjectID of the group in which we are going to assign the mailboxes.
$GroupId = "5a-b8a8-47db-7b-6e9f3"

# Get all shared mailboxes.
$SharedMailbox =  Get-Mailbox -Filter {recipienttypedetails -eq "SharedMailbox"} | Select-Object UserPrincipalName

# For each shared mailboxes, find userd id on EntraID and check if it is in the group or not. If it is not there, add it.
foreach ($mail in $SharedMailbox){

    $user = Get-MgUser -UserId $mail.UserPrincipalName
    if (-not(Get-MgUserMemberOf -UserId $User.Id).id.Contains($GroupId)) {

        New-MgGroupMember -GroupId $GroupId -DirectoryObjectId $User.Id
        Write-Output "Added:" $mail.UserPrincipalName

    } 
    
}