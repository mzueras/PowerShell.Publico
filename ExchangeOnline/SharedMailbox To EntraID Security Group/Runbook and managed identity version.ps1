<#
    .SYNOPSIS

        Sync user principal name from shared mailbox to security group.

    .DESCRIPTION

        Search all shared mailbox and gets UPN from Exchange Online.
        Adds (if not exist) the UPN to a security group on Entra ID.

    .PARAMETER $domain
        Specifies the primary domain in format .onmicrosoft.com.
        You can find this on EntraID > Overview > Primary Domain.

    .PARAMETER $days
        Search for mailboxes created in the last $n days.
    
    .PARAMETER $GroupId
        Group ID from security group on Entra ID with all shared mailboxes UPN.

    .LINK
        (Document Wiki is on work in progress)

#>


# Variable (ejem: companyname.onmicrosoft.com) and days for improve filtering y and the execution time on Azure Runbook:
$domain = "mydomain.onmicrosoft.com"
$days = "-5"

# ObjectID of the group in which we are going to assign the mailboxes.
$GroupId = "5a-b8a8-47db-7b-6e9f3"

# Connect to Exchange and Graph with managed identity.
Connect-ExchangeOnline -ManagedIdentity -Organization $domain -ShowBanner:$false
Connect-MgGraph -Identity

# Get all shared mailboxes.
$DateInPast = (Get-date).AddDays($days)
$SharedMailbox =  Get-Mailbox -recipienttypedetails SharedMailbox | Where-Object {$_.WhenMailboxCreated -gt $DateInPast} | Select-Object UserPrincipalName

# For each shared mailboxes, find userd id on EntraID and check if it is in the group or not. If it is not there, add it.
foreach ($mail in $SharedMailbox){

    $user = Get-MgUser -UserId $mail.UserPrincipalName
    if (-not(Get-MgUserMemberOf -UserId $User.Id).id.Contains($GroupId)) {

        New-MgGroupMember -GroupId $GroupId -DirectoryObjectId $User.Id
        Write-Output "Agregado:" $mail.UserPrincipalName

    } 
    
}