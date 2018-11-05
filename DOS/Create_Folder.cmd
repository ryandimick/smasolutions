if exist %1 goto FOLDEREXISTS

mkdir %1
exit 

:FOLDEREXISTS
echo %1 already existed so no action was required.
exit