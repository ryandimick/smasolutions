rem %1 = The name of the file whose size the script is checking.
rem %2 = The minimum size allowed for the script to exit with an exit code of 0.

if %~z1 GTR %2 goto LARGEFILE
echo The file (%1) is smaller than %2.
exit

:LARGEFILE
echo The file (%1) is larger than %2. This script will end with an Error Code of 100.
exit 100

