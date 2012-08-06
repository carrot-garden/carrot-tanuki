<!--

    Copyright (C) 2010-2012 Andrei Pozolotin <Andrei.Pozolotin@gmail.com>

    All rights reserved. Licensed under the OSI BSD License.

    http://www.opensource.org/licenses/bsd-license.php

-->

### info

folder for log files
* service wrapper logs 
* application logs

### folder permissions note:

the service wrapper will not start if it does not have write permissions to this "log" folder;
in this scenario service can not produce any logs, and it will just fail silently;
this can produce some confusion, hence please set permissions properly.
