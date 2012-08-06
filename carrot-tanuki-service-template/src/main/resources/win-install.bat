@REM
@REM Copyright (C) 2010-2012 Andrei Pozolotin <Andrei.Pozolotin@gmail.com>
@REM
@REM All rights reserved. Licensed under the OSI BSD License.
@REM
@REM http://www.opensource.org/licenses/bsd-license.php
@REM

@echo off
setlocal

rem
rem	${mavenStamp}
rem

rem
rem Install the Wrapper as an NT service.
rem

rem accepts optional password parameter
set PASS=%1
rem echo PASS : '%PASS%'

set CMD_PATH=%~dp0

call "%CMD_PATH%\win-wrapper-manager.bat" INSTALL %PASS%
