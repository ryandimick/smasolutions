param
(
    [String]$server,     #server name
    [String]$drive,      #drive letter
    [String]$freespace   #amount of free space desired (in percent)
)

#1073741824 bytes per gb if doing in GB instead of percent

$available = (((Get-WmiObject Win32_LogicalDisk -ComputerName $server -Filter "DeviceID='${drive}:'").FreeSpace)/((Get-WmiObject Win32_LogicalDisk -ComputerName $server -Filter "DeviceID='${drive}:'").Size)) * 100
$trimmed = $available -as [int]

#Checks amount of free disk space 
if ($available -lt $freespace)
{
  write-host "Low Disk Space! -- $server $drive drive, $trimmed% free"
  Exit $trimmed
}
else
{
    write-host "$trimmed% free on $server $drive drive"
}