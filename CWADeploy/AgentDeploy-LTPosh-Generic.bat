@echo off
REM This script can be safely called as a startup script or from a repeating scheduled task. It will quickly test if an agent is installed and running and exit if found.
REM Options for execution:
REM Use Location ID provided below: "AgentDeploy-LTPosh.bat"
REM Provide Location ID at runtime: "AgentDeploy-LTPosh.bat <LOCATIONID>"

SETLOCAL ENABLEEXTENSIONS
REM SET DEFAULT
SET "LTServerHostname=labtech.mymspname.here"
SET "LTLOCATIONID=1" & REM Set the default location ID to install from if LTINSTALLEXE is not found and no site is passed as a command line parameter.
IF "%LTServerHostname%"=="labtech.mymspname.here" echo Must configure the LTServerHostname value && exit /b 0
REM Set LTLOCATIONID if found as a command line parameter.
IF NOT "[%~1]"=="[]" ECHO "%~1"|findstr /r /c:"[0-9]">NUL&&ECHO "%~1"|findstr /v /r /c:"[^0-9""]">NUL&&SET "LTLOCATIONID=%~1"&&echo Setting Location ID to "%~1"&&shift /1

REM Create Date/Time as YYYYMMDDHHMMSS
REM DATE/TIME format expected: "Day MM/DD/YYYY HH:MM:SS.ss" - Other formats will break the value of "DATETIME"
SET "DATETIME=%date:~10,4%%date:~7,2%%date:~4,2%-%time:~0,2%%time:~3,2%%time:~6,2%"
REM Alternate DATE/TIME format expected: "Day DD/MM/YYYY HH:MM:SS.ss" - Other formats will break the value of "DATETIME"
REM SET "DATETIME=%date:~10,4%%date:~4,2%%date:~7,2%-%time:~0,2%%time:~3,2%%time:~6,2%"
REM Logged output is dumped out at the end of the script. LOGGINGPATH must be defined.
REM If you want each command's output to be dumped to CON as the script executes, set LOGGINGPATH=CON
SET LOGGINGPATH="%temp%\ltagentdeploy-%DATETIME: =%.txt"

:StartHealthCheck
REM Checking for correct server registration, advance to install if valid server address not found
reg query "HKLM\Software\LabTech\Service\Settings" 2>NUL | findstr /i /c:"%LTServerHostname%" > NUL || GOTO PrepareForInstall

REM Checking for running Labtech Service, Exit if found.
sc query LTService 2>NUL | findstr /i /c:"STATE" | findstr /i /c:"RUNNING" > NUL && EXIT /B

REM Checking for running Labtech Service Monitor, Exit if found.
sc query LTSvcMon 2>NUL | findstr /i /c:"STATE" | findstr /i /c:"RUNNING" > NUL && EXIT /B

REM Checking for Labtech Service, advance to install if not found
sc query LTService 2>NUL | findstr /i /c:"SERVICE_NAME" > NUL || GOTO PrepareForInstall

REM Try to start the services, see if they are failing and need to be reinstalled
net start LTService > NUL 2>&1
net start LTSvcMon > NUL 2>&1

REM Pause for 5 seconds
ping -n 5 127.0.0.1 > NUL 2>&1

REM Checking for running Labtech Service, Exit if found.
sc query LTService 2>NUL | findstr /i /c:"STATE" | findstr /i /c:"RUNNING" > NUL && EXIT /B

REM Pause for 15 seconds
ping -n 15 127.0.0.1 > NUL 2>&1

REM Checking for running Labtech Service, Exit if found.
sc query LTService 2>NUL | findstr /i /c:"STATE" | findstr /i /c:"RUNNING" > NUL && EXIT /B

REM Something is wrong, let's reinstall the agent. This is the point of no return unless the script encounters an error.

:PrepareForInstall
REM Fixup the log path in case it was set with quotes.
SET LOGGINGPATH=%LOGGINGPATH:"=%

REM Determine Windows Product and Version
SET "WVER="
FOR /F "usebackq tokens=2 delims==" %%A IN (`type "C:\Windows\system32\prodspec.ini"  2^>NUL ^| find /i "Product=" `) DO @SET "WVER=%%~A"
IF NOT DEFINED WVER FOR /F "usebackq tokens=2*" %%A IN (`reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName  2^>NUL ^| find /i "ProductName"`) DO @SET "WVER=%%~B"
FOR /F "usebackq tokens=2 delims=[]" %%A IN (`ver`) DO SET "WVER=%WVER% %%~A"
SET "WVER=%WVER:)=^)%"
SET "WVER=%WVER:(=^(%"
SET "WVER=%WVER:&=%"
SET "WVER=%WVER:"=%"
SET "WVER=%WVER:^^=%"
SET "WVER=echo %WVER%"

REM Unknown Windows Version?
%WVER% | FINDSTR /R /C:"Version [5-9]\." /C:"Version 10\." > NUL || ( Call ::TheEnd ERROR - Unrecognized Windows Version & exit /b 1 )

pushd "%WINDIR%\Temp" >> "%LOGGINGPATH%" 2>&1
SET "TSMode=QUERY"

ECHO %DATE% %TIME% - Check for Server OS:  >> "%LOGGINGPATH%"
%WVER% | FINDSTR /R /C:" Server " > NUL && (
ECHO %DATE% %TIME% - Found. Check for Terminal Server >> "%LOGGINGPATH%"
CHANGE USER /QUERY 2>NUL | FINDSTR /I /C:"Remote Administration" > NUL || (
ECHO %DATE% %TIME% - Terminal Server found. Check for Terminal Server Install Mode >> "%LOGGINGPATH%"
SET "TSMode=EXECUTE"
CHANGE USER /QUERY 2>NUL | FINDSTR /I /C:"Execute" > NUL || SET "TSMode=INSTALL"
)
)
IF "%TSMode%"=="EXECUTE" ECHO Changing TS Mode to /INSTALL&&CHANGE USER /INSTALL >> "%LOGGINGPATH%" 2>&1

ECHO %DATE% %TIME% - Launching Agent Install command: "Reinstall-LTService -Server '%LTServerHostname%' -LocationID %LTLOCATIONID%" >> "%LOGGINGPATH%"

"%windir%\system32\WindowsPowerShell\v1.0\powershell.exe" "(new-object Net.WebClient).DownloadString('http://bit.ly/LTPoSh') | iex; Reinstall-LTService -Server '%LTServerHostname%' -LocationID %LTLOCATIONID%"  <NUL >>"%LOGGINGPATH%" 2>&1

sc query LTService 2>NUL | findstr /i /c:"Service_name" > NUL || ( Call ::TheEnd ERROR - LTService was not successfully installed & exit /b 1 )
ECHO %DATE% %TIME% - Success! LTService is installed. >> "%LOGGINGPATH%"

popd

:TheEnd
IF NOT "[%~1]"=="[]" ECHO %DATE% %TIME% - %* >> "%LOGGINGPATH%"
IF NOT DEFINED WVER SET "WVER=echo Windows Version was not detected."
%WVER% | FINDSTR /R /C:" Server " > NUL && IF DEFINED TSMode IF NOT "%TSMode%"=="QUERY" CHANGE USER /%TSMode% >> "%LOGGINGPATH%" 2>&1
IF NOT "%LOGGINGPATH%"=="CON" ( TYPE "%LOGGINGPATH%" 2>NUL )
ENDLOCAL
exit /b
