#!/bin/bash
#
# Copyright (C) 2010-2012 Andrei Pozolotin <Andrei.Pozolotin@gmail.com>
#
# All rights reserved. Licensed under the OSI BSD License.
#
# http://www.opensource.org/licenses/bsd-license.php
#

#
#	${mavenStamp}
#

# real location of this script, un-linked if needed
REAL_PATH="$(dirname "$(readlink -f -n $0)")"

"$REAL_PATH/nix-wrapper-manager.sh" stop
