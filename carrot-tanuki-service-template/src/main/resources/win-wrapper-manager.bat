@REM
@REM Copyright (C) 2010-2012 Andrei Pozolotin <Andrei.Pozolotin@gmail.com>
@REM
@REM All rights reserved. Licensed under the OSI BSD License.
@REM
@REM http://www.opensource.org/licenses/bsd-license.php
@REM

rem #######################

rem build properties

rem
rem	${mavenStamp}
rem

rem #######################

rem script parameters

rem command name
set NAME=%1

rem used by "INSTALL" command
set PASS=%2

rem #######################

rem setup vars

rem location of this script
set CMD_PATH=%~dp0

rem location of wrapper binary files
set BIN_PATH=%CMD_PATH%\bin

rem wrapper name prefix
set WRAPPER_NAME=wrapper

rem location of wrapper conf file
set WRAPPER_CONF=%CMD_PATH%\conf\%WRAPPER_NAME%.properties

rem #######################

rem check OS

if /i "%OS%"=="Windows_NT" goto :DETECT_ARCH
echo ERROR: This script only works with NT-based versions of Windows.
pause
goto :EOF

rem #######################

rem detect cpu architecture

:DETECT_ARCH

set WRAPPER_X=%WRAPPER_NAME%-windows-x86

if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" goto :ARCH_X64
if /i "%PROCESSOR_ARCHITEW6432%"=="AMD64" goto :ARCH_X64
if /i "%PROCESSOR_ARCHITECTURE%"=="X86"   goto :ARCH_X32
echo ERROR: Can not detect PROCESSOR_ARCHITECTURE.
pause
goto :EOF

:ARCH_X64
echo INFO: Detected ARCH_X64. 
set WRAPPER_64=%WRAPPER_X%-64.exe
set WRAPPER_SRC=%BIN_PATH%\%WRAPPER_64%
set WRAPPER_EXE=%CMD_PATH%\%WRAPPER_64%
goto :TEST_COPY 

:ARCH_X32
echo INFO: Detected ARCH_X32. 
set WRAPPER_32=%WRAPPER_X%-32.exe
set WRAPPER_SRC=%BIN_PATH%\%WRAPPER_32%
set WRAPPER_EXE=%CMD_PATH%\%WRAPPER_32%
goto :TEST_COPY

rem #######################

rem test/copy detected binary

:TEST_COPY

if exist "%WRAPPER_EXE%" goto :VALIDATE_COMMAND
 
copy /b /y "%WRAPPER_SRC%" "%WRAPPER_EXE%"
 
if exist "%WRAPPER_EXE%" goto :VALIDATE_COMMAND 

echo ERROR: Unable to locate a Wrapper executable:
echo %WRAPPER_EXE%
echo %WRAPPER_SRC%
pause
goto :EOF


rem #######################

:VALIDATE_COMMAND

rem find the requested command

for /F %%v in ('echo %NAME%^|findstr /i "^console$ ^start$ ^pause$ ^resume$ ^stop$ ^restart$ ^install$ ^uninstall"') do call :RUN_WIN_CMD set COMMAND=%%v

if "%COMMAND%" == "" (
    echo Usage: %0 { console : start : pause : resume : stop : restart : install : uninstall }
    pause
    goto :EOF
) else (
    shift
    goto :EXECUTE_COMMAND
)

rem #######################

rem at runtime the current directory will be that of %CMD_PATH%\wrapper-XXX.exe

:EXECUTE_COMMAND

call :%COMMAND%
if errorlevel 1 pause
goto :EOF

rem #######################

rem command dictionary

rem can be one of:
rem   -c  --console run as a Console application
rem   -t  --start   starT an NT service
rem   -a  --pause   pAuse a started NT service
rem   -e  --resume  rEsume a paused NT service
rem   -p  --stop    stoP a running NT service
rem   -i  --install Install as an NT service
rem   -it --installstart Install and sTart as an NT service
rem   -r  --remove  Remove as an NT service
rem   -l=<code> --controlcode=<code> send a user controL Code to a running NT service
rem   -d  --dump    request a thread Dump
rem   -q  --query   Query the current status of the service
rem   -qs --querysilent Silently Query the current status of the service
rem   -v  --version print the wrapper's version information.
rem   -?  --help    print this help message

:CONSOLE
"%WRAPPER_EXE%" --console "%WRAPPER_CONF%"
goto :EOF

:START
"%WRAPPER_EXE%" --start   "%WRAPPER_CONF%"
goto :EOF

:PAUSE
"%WRAPPER_EXE%" --pause   "%WRAPPER_CONF%"
goto :EOF

:RESUME
"%WRAPPER_EXE%" --resume  "%WRAPPER_CONF%"
goto :EOF

:STOP
"%WRAPPER_EXE%" --stop    "%WRAPPER_CONF%"
goto :EOF

rem accepts optional password parameter or prompts user for a password 
:INSTALL
rem echo PASS : '%PASS%'
rem use provided password
if '%PASS%'=='' goto :INSTALL_PROMPT
"%WRAPPER_EXE%" --install "%WRAPPER_CONF%" wrapper.ntservice.password=%PASS%
goto :EOF
rem ask to input password
:INSTALL_PROMPT
"%WRAPPER_EXE%" --install "%WRAPPER_CONF%" wrapper.ntservice.password.prompt=TRUE wrapper.ntservice.password.prompt.mask=FALSE
goto :EOF

:UNINSTALL
"%WRAPPER_EXE%" --remove  "%WRAPPER_CONF%"
goto :EOF

:RESTART
call :STOP
call :START
goto :EOF

rem #######################

rem helps to set variable value

:RUN_WIN_CMD
%*
goto :EOF
