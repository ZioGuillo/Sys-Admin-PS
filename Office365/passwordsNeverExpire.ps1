#reads file C:\scripts\emails.txt and will set all users listed in said file to have passwords never expire in Office365 Exchange

$credential = Get-Credential

Connect-MsolService -Credential $credential

ForEach ($u in [System.IO.File]::ReadLines("C:\Scripts\emails.txt"))
{
	Set-MsolUser -UserPrincipalName $u -PasswordNeverExpires $true
}
