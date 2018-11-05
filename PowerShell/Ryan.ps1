$fileName = "C:\Program Files\OpConxps\SMAFICSConnector\Response\TDR Mod Def Loan Selection.txt"
$columnToGet = 0
$columns = gc $fileName | 
   %{ $_.Split(",",[StringSplitOptions]"RemoveEmptyEntries")[$columnToGet] +"," }
$columns | Out-File "C:\Program Files\OpConxps\SMAFICSConnector\Response\OutputWithLastCommaTDR.txt"

$file = gc "C:\Program Files\OpConxps\SMAFICSConnector\Response\OutputWithLastCommaTDR.txt"
for($i = $file.count;$i -ge 0;$i--){if($file[$i] -match ","){$file[$i] = $file[$i] -replace ",";break}}
$file|out-file "C:\Program Files\OpConxps\SMAFICSConnector\Response\OutputWithoutLastCommaTDR.txt" -force