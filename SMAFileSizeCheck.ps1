#   Syntax:
#	SMAFileSizeCheck.ps1 -fileToCheck "C:\Test\File1.txt" -size 100
#
#

param (
	[string]$fileToCheck,
    [int]$size
)

try
{
   Test-Path $fileToCheck
   
   if ((Get-Item $fileToCheck).Length -ge $size.byte)
   {
        echo "$fileToCheck is greater than or equal to $size"
        exit 0
   }
   else
   {
        echo "$fileToCheck is not greater than or equal to $size"
        exit 7509
   }
}
catch [System.AccessViolationException]
{
    echo "Error.  User does not have access" + $Error[0]
	exit 7507
}
