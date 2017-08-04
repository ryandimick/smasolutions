#	Syntax:
#	SMAConvertToCVS.ps1 -sourcePath "C:Test\report\" -sourceFileName 12345 -destinationPath "\\opcon\report\ -destinationFileName tbal -sheetName OpCon
#
#	 

param (
    [string]$sourcePath,
    [string]$sourceFileName,
    [string]$destinationPath,
    [string]$destinationFileName,
    [string]$sheetName
)

try
{
    if (Test-Path $sourcePath And Test-Path $destinationPath)
        {
            echo "Error.  Folder path not reachable"
            exit 7518
        }
    else 
        {
        $excel = New-Object -ComObject Excel.Application
        $excel.Visible = $false
        $excel.DisplayAlerts = $false

        $workbook = $excel.Workbooks.Open($sourcePath)
        $WorkSheet = $WorkBook.sheets.item("$sheetName")
        $xlCSV = 6
        $workbook.saveas($destinationPath,$xlCSV)

$excel.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($objExcel)
        }
}

catch [System.AccessViolationException]
{
	echo "Error.  User does not have access" + $Error[0]
	exit 7507
}