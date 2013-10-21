@echo off
REM 
REM author    Brian Stoots
REM email     bstoots@gmail.com
REM date      2013-10-20
REM summary   This script will need to be run before any config deployment can occur.
REM           It checks whether the current Powershell ExecutionPolicy is set to Unrestricted.
REM           If not it creates a batch script to revert to the current policy level and
REM           then attempts to set the policy to Unrestricted.
REM

echo Checking current Powershell ExecutionPolicy ... 
for /f %%i in ('powershell Get-ExecutionPolicy') do set RESULT=%%i
if "%RESULT%"=="Unrestricted" (
  echo Current ExecutionPolicy is %RESULT%, great!
  exit /B 0
)
if not "%RESULT%"=="Unrestricted" (
  echo Current ExecutionPolicy is %RESULT%, this isn't going to cut it
  echo Creating reset-ps-execution-policy.bat ...
  if exist reset-ps-execution-policy.bat (
    REM Don't overwrite existing reset scripts.  If the existing script is old you should
    REM manually remove it.
    echo reset-ps-execution-policy.bat already exists!  Exiting.
    exit /B 1
  )
  if not exist reset-ps-execution-policy.bat (
    For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c-%%a-%%b)
    For /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set mytime=%%a%%b)
    echo @echo off>reset-ps-execution-policy.bat
    echo :: %mydate%_%mytime%>>reset-ps-execution-policy.bat
    echo echo Resetting Powershell ExecutionPolicy to %RESULT% ...>>reset-ps-execution-policy.bat
    echo powershell Set-ExecutionPolicy %RESULT%>>reset-ps-execution-policy.bat
    echo echo Success!>>reset-ps-execution-policy.bat
    REM Note: the reset script will automatically delete itself after executing
    echo del %%0>>reset-ps-execution-policy.bat
    echo Attempting to Set-ExecutionPolicy to Unrestricted ...
    powershell Set-ExecutionPolicy Unrestricted
    echo Success!
    exit /B 0
  )
)
exit /B 0