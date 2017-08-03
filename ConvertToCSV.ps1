$sourcePath = $args[0]
$destPath = $args[1]

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false

$workbook = $excel.Workbooks.Open($sourcePath)

$xlCSV = 6
$workbook.saveas($destPath,$xlCSV)

$excel.Quit()