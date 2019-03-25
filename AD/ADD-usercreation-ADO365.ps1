<#
.SYNOPSIS
Creates a user account in active directory with information entered in by the user.

.DESCRIPTION
This will create a user in Active Directory automatically with Powershell.

.NOTES
Name: AD-CreateUserNoMailbox.ps1
Version: 1.0
Date of last revision:

#>

clear

#Capture administrative credential for future connections.

Set-ExecutionPolicy RemoteSigned

#$smtpServer="smtp.office365.com"

$userid='admin email'
$pwd= get-content C:\Server_PS_Scripts\credentials\cred01.txt | convertto-securestring
$creds = New-Object System.Management.Automation.PSCredential($userid,$pwd)

$global:session365 = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $creds -Authentication Basic -AllowRedirection

Import-PSSession $global:session365 -AllowClobber

Connect-MsolService -Credential $creds

#Checking if the shell is running as administrator.
#Requires -RunAsAdministrator
#Requires -Module ActiveDirectory

$title1 = "Create a User Account in Active Directory/Office365/Slack"

$host.ui.RawUI.WindowTitle = $title1

Import-Module ActiveDirectory -EA Stop

sleep 5
cls

#Variables
$Company = " "
$Office  = " "
$Country = "US"
$DLO365  = "Distribution List name"

#Variables for Slack Invitation API
$URL = "https://slack.com/api"
$Endpoint = "/users.admin.invite?token="

#Security Token from Slack
$Token = "Slack Token"

$URLSecure = "$URL$Endpoint$Token"
$EndpointEmail   = "&email="
$Endpoinchannels = "&channels="
$Endpointfn = "&first_name="
$Endpointln = "&last_name="
$DesmondID = "ID Channels"

#----------------------------------------------------------------------------------


Write-Host
Write-Host
#Getting variable for the First Name
$firstname = Read-Host "Enter in the First Name"
Write-Host
#Getting variable for the Last Name
$lastname = Read-Host "Enter in the Last Name"
Write-Host
#Setting Full Name (Display Name) to the users first and last name
$fullname = "$firstname $lastname"
#Write-Host
#Setting username to first initial of first name along with the last name.
$i = 1
$logonname = $firstname.substring(0,$i) + $lastname
#Setting the employee ID.  Remove the '#' if you want to use the variable
#$empID = Read-Host "Enter in the Employee ID"
#Setting the Path for the OU.
$OU = "OU=LA, OU=Users, OU=Z-Users, DC=ad, DC=axs, DC=com"
#Setting the variable for the domain.
$domain = $env:userdnsdomain
#email setting
$EmailAddress = ($logonname + "@domain.com").ToLower()
#Manager
$Manager = Read-Host "Enter the userID of the Manager"
#Setting the variable for the description.
$Description = Read-Host "Enter in the User Description"
#Department
$Department  = Read-Host "Enter the Department"


cls
#Displaying Account information.
Write-Host "======================================="
Write-Host
Write-Host "Firstname:      $firstname"
Write-Host "Lastname:       $lastname"
Write-Host "Display name:   $fullname"
Write-Host "Logon name:     $logonname"
#Write-Host "OU:             $OU"
#Write-Host "Email:          $EmailAddress"
Write-Host "Manager:        $Manager"
Write-Host "Department:     $Department"
#Write-Host "Domain:         $domain"

#Checking to see if user account already exists.  If it does it
#will append the next letter of the first name to the username.
DO
{
If ($(Get-ADUser -Filter {SamAccountName -eq $logonname})) {
        Write-Host "WARNING: Logon name" $logonname.toUpper() "already exists!!" -ForegroundColor:Green
        $i++
        $logonname = $firstname.substring(0,$i) + $lastname
        Write-Host
        Write-Host
        Write-Host "Changing Logon name to" $logonname.toUpper() -ForegroundColor:Green
        Write-Host
        $taken = $true
        sleep 10
    } else {
    $taken = $false
    }
} Until ($taken -eq $false)
$logonname = $logonname.toLower()

cls
#Displaying account information that is going to be used.
Write-Host "======================================="
Write-Host
Write-Host "Firstname:      $firstname"
Write-Host "Lastname:       $lastname"
Write-Host "Display name:   $fullname"
Write-Host "Logon name:     $logonname"
#Write-Host "OU:             $OU"
#Write-Host "Email:          $EmailAddress"
Write-Host "Manager:        $Manager"
Write-Host "Department:     $Department"
#Write-Host "Domain:         $domain"



#Setting minimum password length to 12 characters and adding password complexity.
$PasswordLength = 8

Do
{
Write-Host
    $isGood = 0
    $Password = Read-Host "Enter in the Password" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    $Complexity = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

    if ($Complexity.Length -ge $PasswordLength) {
                Write-Host
            } else {
                Write-Host "Password needs $PasswordLength or more Characters" -ForegroundColor:Green
        }

    if ($Complexity -match "[^a-zA-Z0-9]") {
                $isGood++
            } else {
                Write-Host "Password does not contain Special Characters." -ForegroundColor:Green
        }

    if ($Complexity -match "[0-9]") {
                $isGood++
            } else {
                Write-Host "Password does not contain Numbers." -ForegroundColor:Green
        }

    if ($Complexity -cmatch "[a-z]") {
                $isGood++
            } else {
                Write-Host "Password does not contain Lowercase letters." -ForegroundColor:Green
        }

    if ($Complexity -cmatch "[A-Z]") {
                $isGood++
            } else {
                Write-Host "Password does not contain Uppercase letters." -ForegroundColor:Green
        }

} Until ($password.Length -ge $PasswordLength -and $isGood -ge 3)


Write-Host
Read-Host "Press Enter to Continue Creating the Accounts"
Write-Host "Creating Office365 user account now" -ForegroundColor:Red
#Creating user account with the information you inputted.

New-MsolUser -DisplayName $fullname -FirstName $firstname -LastName $lastname -UserPrincipalName $EmailAddress -UsageLocation $Country  -LicenseAssignment Contoso.com:STANDARDPACK -Password <password> -ForceChangePassword $TRUE

sleep 120

try {
        Set-User -Identity $EmailAddress -Country $Country -Title $Description -Department $Department -Office $Office -Manager $Manager
        Add-DistributionGroupMember -Identity $DLO365 -Member $EmailAddress



    }catch {
        Write-Host "ERROR IN THE INFORMATION" -ForegroundColor:Red
    }

Write-Host Get-MsolUser -UserPrincipalName $EmailAddress

#-------------------------------------------

sleep 5

cls

Write-Host "Creating Active Directory user account now" -ForegroundColor:Red

#Creating user account with the information you inputted.

New-ADUser -Name $fullname -GivenName $firstname -Surname $lastname -DisplayName $fullname -SamAccountName $logonname -UserPrincipalName $logonname@$Domain `
-AccountPassword $password -EmailAddress $EmailAddress -Company $Company -Office $Office -Title $Description -Department $Department  `
-enabled $TRUE -Path $OU -Description $Description -Manager $Manager -Confirm:$false



sleep 5


Write-Host

$ADProperties = Get-ADUser $logonname -Properties *
#$O365Properties

#Ready to Deploy the invitation
$URLSlack = "$URLSecure$EndpointEmail$EmailAddress$Endpoinchannels$DesmondID"

#Sending the Slack invitation to the User.
$slackCM = Invoke-RestMethod -Method Post -Uri $URLSlack


Get-PSSession | Remove-PSSession



Sleep 3

cls

Write-Host "========================================================" -ForegroundColor:Red
Write-Host "The account was created with the following properties:"   -ForegroundColor:Red
Write-Host
Write-Host "Firstname:      $firstname"
Write-Host "Lastname:       $lastname"
Write-Host "Display name:   $fullname"
Write-Host "Logon name:     $logonname"
Write-Host "Email:          $EmailAddress"
Write-Host "Manager:        $Manager"
Write-Host "Department:     $Department"
Write-Host "AD Properties" -ForegroundColor:Red
Write-Host "OU:             $OU"
Write-Host "Domain:         $domain"
Write-Host "Member of:             "
Write-Host "O365 Properties" -ForegroundColor:Red
Write-Host "DL Member:      $DLO365"
Write-Host "Slack:          $slackCM.error"
Write-Host
