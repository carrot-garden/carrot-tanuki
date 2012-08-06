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
rem Disable the Wrapper NT service.
rem

set SERVICE=${serviceName}

rem note: '=' is part of option name
sc config "%SERVICE%" start= disabled
