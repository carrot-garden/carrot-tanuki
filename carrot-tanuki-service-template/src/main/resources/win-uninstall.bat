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
rem Uninstall the Wrapper as an NT service.
rem

set CMD_PATH=%~dp0

call "%CMD_PATH%\win-wrapper-manager.bat" STOP
call "%CMD_PATH%\win-wrapper-manager.bat" UNINSTALL
