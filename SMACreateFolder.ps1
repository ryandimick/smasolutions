#   Syntax:
#	SMACreateFolder.ps1 -newFolderPathToCreate C:\Test\Archive
#
#

param (
	[string]$newFolderPathToCreate
)

try
{
    if (Test-Path $newFolderPathToCreate)
        {
            echo "Error.  Folder already exists"
            exit 7508
        }
    else 
        {
	        New-Item $newFolderPathToCreate -type directory
        }
}

catch [System.AccessViolationException]
{
	echo "Error.  User does not have access" + $Error[0]
	exit 7507
}
