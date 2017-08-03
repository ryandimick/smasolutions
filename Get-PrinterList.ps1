cls
Write-Host "Getting list of printers"
$creds = get-credential
Get-WMIObject -Class Win32_Printer -ComputerName eprintserver -Credential $creds -Property * | select name,location | sort name | Export-Csv .\PrinterList.csv -NoTypeInformation
Read-Host "Done. Press any key to quit"