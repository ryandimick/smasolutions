@echo off
REM ####################################################
REM # This script looks for the number of files under  #
REM # a folder specified on parameter %1               #
REM # and concatenates all filenames into a variable   #
REM # to store the content of this variable in an      #
REM # OpCon Global Property.                           #
REM #                                                  #
REM # The parameters for this script are:              #
REM # 		%1 The path for the TEMP RECON files       #
REM #       %2 Name of Global Property to SET          #
REM # 		%3 The OpCon MSGIN folder                  #
REM #       %4 The OpCon Events User                   #
REM #       %5 The OpCon Events Password               #
REM #                                                  #
REM # Possible Exit Codes for the Script:              #
REM #	0 - Finished OK                                #
REM #	1 - Parameter 1 is missing                     #
REM #   2 - Parameter 2 is missing                     #
REM #   3 - Parameter 3 is missing                     #
REM #   4 - Parameter 4 is missing                     #
REM #   5 - Parameter 5 is missing                     #
REM #   6 - No files found                             #

set exitCode=0

REM ### Validating parameters ###
echo ### Validating Parameters ###
if "%1%" == "" (
	echo ********* The path for the RECON TEMP files is missing - SCRIPT ABORTING WITH EXIT CODE 1 *********
	set exitCode=1
	goto scriptError
)
if "%2%" == "" (
	echo ********* The name of the Global Property is missing - SCRIPT ABORTING WITH EXIT CODE 2 *********
	set exitCode=2
	goto scriptError
)
if "%3%" == "" (
	echo ********* The OpCon MSGIN folder is missing - SCRIPT ABORTING WITH EXIT CODE 3 *********
	set exitCode=3
	goto scriptError
)
if "%4%" == "" (
	echo ********* The OpCon Events User is missing - SCRIPT ABORTING WITH EXIT CODE 4 *********
	set exitCode=4
	goto scriptError
)
if "%5%" == "" (
	echo ********* The OpCon Events Password is missing - SCRIPT ABORTING WITH EXIT CODE 5 *********
	set exitCode=5
	goto scriptError
)

REM ### Checking number of files and filenames ###
echo ### Checking number of files and filenames under %1 ###
setlocal enabledelayedexpansion

REM ### Checking the number of files under the specified folder ###
echo ### Checking the number of files under %1 ###
set numFiles=0
for %%x in (%1\pdf*.*) do (
  set file[!numFiles!]=%%~nxx
  set /a numFiles+=1
 ) 
echo ### Number of files found: %numFiles% ###

REM ### If there are no files to process, the script wil abort ###
if "%numFiles%" == "0" (
	echo ********* NO FILES WERE FOUND - SCRIPT ABORTING WITH EXIT CODE 6 *********
	set exitCode=6
	goto scriptError
)

REM ### Checking number of files to mount EVENT COMMAND ###
echo ### Checking number of files to mount EVENT COMMAND ###
set commandPart1=$PROPERTY:SET,%2,
set commandPart2=FILE=
set commandPart2A=LASTDAY=
set commandOpConUser=%4
set commandOpConpw=%5
set commandFinal=""

REM ### Setting the EVENT for 1 file ###
if "%numFiles%" == "1" (
set commandFinal=%commandPart1%%commandPart2%%file[0]%,%commandOpConUser%,%commandOpConpw%
echo !commandFinal!
goto scriptOk
)

REM ### Setting the EVENT for 2 files ###
if "%numFiles%" == "2" (set commandFinal=%commandPart1%%commandPart2%%file[0]% %commandPart2A%%file[1]%,%commandOpConUser%,%commandOpConpw%
echo !commandFinal!
goto scriptOk
)

REM ### Setting the EVENT for 3 files ###
if "%numFiles%" == "3" (set commandFinal=%commandPart1%%commandPart2%%file[0]% %commandPart2%%file[1]% %commandPart2A%%file[2]%,%commandOpConUser%,%commandOpConpw%
echo !commandFinal!
goto scriptOk
)

REM ### Setting the EVENT for 4 files ###
if "%numFiles%" == "4" (set commandFinal=%commandPart1%%commandPart2%%file[0]% %commandPart2%%file[1]% %commandPart2%%file[2]% %commandPart2A%%file[3]%,%commandOpConUser%,%commandOpConpw%
echo !commandFinal!
goto scriptOk
)

:scriptOk
REM ### Creates the file with the $PROPERTY:SET event ###
echo ### Creating the file with the $PROPERTY EVENT into the OpCon MSGIN Directory: %3
echo !commandFinal! >> %3\ReconEvent.txt
echo ### Script finsihed Ok ###
exit /B %exitCode%
endlocal

:scriptError
REM ### Aborts the script if there is a problem ###
exit /B %exitCode%
endlocal
