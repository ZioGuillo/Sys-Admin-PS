################################################################################# 
## 
## Server Health Check 
## Created by Sravan Kumar S  
## Date : 3 Mar 2014 
## Version : 1.0 
## Email: sravankumar.s@outlook.com   
## This scripts check the server Avrg CPU and Memory utlization along with C drive 
## disk utilization and sends an email to the receipents included in the script
################################################################################ 

##Customized for personal use by Michael Shepard 12/31/2019
#Sends email if RAM use is over $Threshold, otherwise just records data when run

$ServerListFile = "C:\scripts\serverlist" 
$Threshold = "60.0" ##Sets threshold for when RAM will send out email alert
$ServerList = "localhost" ##Get-Content $ServerListFile -ErrorAction SilentlyContinue 
Get-Date -Format g | Out-File -FilePath C:\outfiles\healthcheck.txt -Append
$Result = ForEach($computername in $ServerList) #either use $Serverlist for hardcoded localhost or $ServerListFile for a file of servers to monitor
	{
		$AVGProc = Get-WmiObject -computername $computername win32_processor | 
		Measure-Object -property LoadPercentage -Average | Select Average
		$OS = gwmi -Class win32_operatingsystem -computername $computername |
		Select-Object @{Name = "MemoryUsage"; Expression = {“{0:N2}” -f ((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory)*100)/ $_.TotalVisibleMemorySize) }}
		$vol = Get-WmiObject -Class win32_Volume -ComputerName $computername -Filter "DriveLetter = 'C:'" |
		Select-object @{Name = "C PercentFree"; Expression = {“{0:N2}” -f  (($_.FreeSpace / $_.Capacity)*100) } }
		[PSCustomObject]@{
			"CPU Load" = $AVGProc.Average
			"RAM Usage" = $OS.MemoryUsage
			"HDD Space" = $vol.'C PercentFree'
			}
	}
$Result | Out-File -FilePath C:\outfiles\healthcheck.txt -Append

$RAMWarning = gwmi -Class win32_operatingsystem -computername $computername |
		Where-Object { ((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory)*100)/ $_.TotalVisibleMemorySize) -gt $Threshold}
if ($RAMWarning)
{
	$EmailTo = "EMAIL@EMAIL.COM"
	$EmailFrom = "EMAIL@EMAIL.COM"
	$user = 'EMAIL@EMAIL.COM'
	$password = 'hunter2'
	$Subject = "Alert: Memory Usage over " + $Threshold + "%"
	$Body = "Server Memory Usage has been recorded at  "+ $AVGProc.Average + "%."
	$SMTPServer = "SMTPSERVER"
	$SMTPMessage = New-Object System.Net.Mail.MailMessage($EmailFrom,$EmailTo,$Subject,$Body)
	$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)
	$SMTPClient.EnableSsl = $true
	$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($user, $password)
	$SMTPClient.Send($SMTPMessage)
}
exit
