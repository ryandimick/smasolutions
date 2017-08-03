#	Syntax: psmonitor.ps1 -folderToMonitor "C:\a" 
#							-intervalInSeconds 30 
#							-watchLengthInSeconds 120 
#							-msginInPathFile "C:\a1"
#							-opconEvent "$JOB:RELEASE,CURRENT,schedulename,jobname,ocadm,pw"
#	Incoming parameters:
#	1. Folder path (folder that will be monitored)
#	2. Number seconds interval to check for activity, i.e. 30 seconds
#	3. Number seconds to watch, watch window length, i.e. 3600 seconds
#	4. MSGIN path, unique filename (OpCon event file when no file)
#	5. OpCon event, i.e. notify:email, job:add, etc.
#	
Param(
  [string]$folderToMonitor,
  [int]$intervalInSeconds,
  [int]$watchLengthInSeconds,
  [string]$msginInPathFile,
  [string]$opconEvent  
)
$filesDetected = "false"
$timeout = new-timespan -seconds $watchLengthInSeconds
$sw = [diagnostics.stopwatch]::StartNew()
while ($sw.elapsed -lt $timeout){
	if((Get-ChildItem $folderToMonitor -force | 
			Select-Object -First 1 | 
			Measure-Object).Count -ne 0)
	{
		$filesDetected = "true"
	}
	sleep $intervalInSeconds
}
if ($filesDetected -ne "true")
{
	#Folder is still empty, write event to MSGIN
	[IO.File]::WriteAllText($msginInPathFile, $opconEvent)
}
