#!/bin/bash
#
# Copyright (C) 2010-2012 Andrei Pozolotin <Andrei.Pozolotin@gmail.com>
#
# All rights reserved. Licensed under the OSI BSD License.
#
# http://www.opensource.org/licenses/bsd-license.php
#

#-----------------------------------------------------------------------------
#
#	${mavenStamp}
#
#-----------------------------------------------------------------------------
# TESTED: redhat (chkconfig)
#
# The following lines are used by the 'chkconfig' init manager.
# 	They should remain commented.
#
# chkconfig:	2 3 4 5		20 80
# description:	${serviceName}
#-----------------------------------------------------------------------------
# TESTED: ubuntu (update-rc.d)
#
# The following lines are used by the LSB-compliant init managers.
# 	They should remain commented.
# 	http://refspecs.freestandards.org/LSB_3.1.0/LSB-Core-generic/LSB-Core-generic/facilname.html
#
### BEGIN INIT INFO
# Provides:          ${serviceName}
# Required-Start:    $local_fs $remote_fs $syslog
# Required-Stop:     $local_fs $remote_fs $syslog
# Should-Start:      $network $named $time
# Should-Stop:       $network $named $time
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: ${description}
# Description:       ${description} [${serviceName}]
### END INIT INFO
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
#--- maven variables can be used from this point on --------------------------
#-----------------------------------------------------------------------------

#
# NOTE: maven variables substitution is ON;
#	do not use ${this-kind-of-constructs} for bash variables
#

#
# NOTE: "." (current directory) reference in this section
#	will be replaced with actual un-linked directory location of this script
#

#
JAVA_CMD="${javaCommand}"

# Application naming convention
APP_NAME="${serviceName}"
APP_LONG_NAME="${description} [${serviceName}]"

#
# Wrapper configuration file location
# main file
WRAPPER_CONF="./conf/wrapper.properties"
#
# Wrapper executable source location & name prefix
# distribution folder; will copy appropriate *.bin from here
WRAPPER_SRC="./bin/wrapper"
#
# Wrapper executable target location & name prefix
# execution folder; will copy appropriate *.bin to this final location
WRAPPER_CMD="./wrapper"
#

# Priority at which to run the wrapper.  See "man nice" for valid priorities.
#  nice is only used if a priority is specified.
PRIORITY=

# Location of the pid file.
# expecting to run as dedicated non-priviliged user, with PID in user home folder
PID_DIR="./"

# If uncommented, causes the Wrapper to be shutdown using an anchor file.
#  When launched with the 'start' command, it will also ignore all INT and
#  TERM signals.
#IGNORE_SIGNALS=true

# Wrapper will start the JVM asynchronously. Your application may have some
#  initialization tasks and it may be desirable to wait a few seconds
#  before returning.  For example, to delay the invocation of following
#  startup scripts.  Setting WAIT_AFTER_STARTUP to a positive number will
#  cause the start command to delay for the indicated period of time
#  (in seconds).
#
WAIT_AFTER_STARTUP=3

# If set, the status, start_msg and stop_msg commands will print out detailed
#   state information on the Wrapper and Java processes.
#
DETAIL_STATUS=true

# If specified, the Wrapper will be run as the specified user.
# IMPORTANT - Make sure that the user has the required privileges to write
#  the PID file and wrapper.log files.  Failure to be able to write the log
#  file will cause the Wrapper to exit without any way to write out an error
#  message.
# NOTE - This will set the user which is used to run the Wrapper as well as
#  the JVM and is not useful in situations where a privileged resource or
#  port needs to be allocated prior to the user being changed.
#
RUN_AS_USER="${serviceUsername}"

#-----------------------------------------------------------------------------
#--- no more maven variables beyond this point -------------------------------
#-----------------------------------------------------------------------------

# depencencies of this script

# use this instead of "echo"
log(){
	# one argument to echo
	echo "### wrapper-manager: $1"
}

# Resolve the location of the 'ps' command
EXE_PS="/usr/bin/ps"
if [ ! -x "$EXE_PS" ] ; then
    EXE_PS="/bin/ps"
    if [ ! -x "$EXE_PS" ] ; then
        log "error: can not find 'ps'"
        exit 1
    fi
fi


# Resolve the location of the 'id' command
EXE_ID="/usr/xpg4/bin/id"
if [ ! -x "$EXE_ID" ] ; then
    EXE_ID="/usr/bin/id"
    if [ ! -x "$EXE_ID" ] ; then
        log "error: can not find 'id'."
        exit 1
    fi
fi
CMD_ID="$EXE_ID -n -u"


# Resolve 'run as user' command
# options
EXE_RUNUSER="/sbin/runuser"
EXE_SU="/bin/su"
# target
CMD_SU=
# Use "runuser" if this exists.  runuser should be used on RedHat in preference to su.
if [ -x $EXE_RUNUSER ] ; then
    CMD_SU="$EXE_RUNUSER"
elif [ -x $EXE_SU ] ; then
    CMD_SU="$EXE_SU"
else
	log "error: can not find 'su'/'runuser'"
	exit 1
fi


# Resolve "service run level" manager
# TESTED: ubuntu, redhat
# target commands:
CMD_SVC_ENABLE=
CMD_SVC_DISABLE=
#
# known managers:
# 	ubuntu
EXE_UPDATERCD="/usr/sbin/update-rc.d"
# 	redhat
EXE_CHKCONFIG="/sbin/chkconfig"
#
# check ubuntu first, redhat second
if [ -x $EXE_UPDATERCD ] ; then
	CMD_SVC_ENABLE="$EXE_UPDATERCD -f $APP_NAME defaults"
	CMD_SVC_DISABLE="$EXE_UPDATERCD -f $APP_NAME remove"
elif [ -x $EXE_CHKCONFIG ] ; then
	CMD_SVC_ENABLE="$EXE_CHKCONFIG --add $APP_NAME"
	CMD_SVC_DISABLE="$EXE_CHKCONFIG --del $APP_NAME"
else
	log "error: can not find 'service run level manager'"
	exit 1
fi


# Resolve "kernel properties manager"
# TESTED: ubuntu, redhat
EXE_SYSCTL="/sbin/sysctl"


# verify limits:
#	socket send/receive maximum buffer size
#	number of open sockets/files
if [ -x $EXE_SYSCTL ] ; then
	SO_RECV_MAX=`$EXE_SYSCTL -n -q net.core.rmem_max`
	SO_SEND_MAX=`$EXE_SYSCTL -n -q net.core.wmem_max`
	VM_SWAP_MODE=`$EXE_SYSCTL -n -q vm.swappiness`
	USER_MAX_OPEN_FILES=`ulimit -n`
	log "info: kernel limits: SO_RECV_MAX=$SO_RECV_MAX; SO_SEND_MAX=$SO_SEND_MAX;"
	log "info: kernel swap mode: VM_SWAP_MODE=$VM_SWAP_MODE;"
	log "info: user max open files: USER_MAX_OPEN_FILES=$USER_MAX_OPEN_FILES;"
else
	log "error: can not find 'kernel properties manager'"
	exit 1
fi


#-----------------------------------------------------------------------------


# Resolve the true real path and name of this script without any sym links;
REAL_PATH="$(dirname  "$(readlink -f -n $0)")"
REAL_NAME="$(basename "$(readlink -f -n $0)")"


# Get the real fully qualified path to this script
SCRIPT="$REAL_PATH/$REAL_NAME"


# Change the current directory to the actual location of the script, unlinked;
cd "$REAL_PATH"


#-----------------------------------------------------------------------------

# If any path below is relative, make it absolute

# make absolute PID_DIR
FIRST_CHAR=`echo $PID_DIR | cut -c1,1`
if [ "$FIRST_CHAR" != "/" ] ; then
    PID_DIR=$REAL_PATH/$PID_DIR
fi

# make absolute WRAPPER_CMD
FIRST_CHAR=`echo $WRAPPER_CMD | cut -c1,1`
if [ "$FIRST_CHAR" != "/" ] ; then
    WRAPPER_CMD=$REAL_PATH/$WRAPPER_CMD
fi

# make absolute WRAPPER_SRC
FIRST_CHAR=`echo $WRAPPER_SRC | cut -c1,1`
if [ "$FIRST_CHAR" != "/" ] ; then
    WRAPPER_SRC=$REAL_PATH/$WRAPPER_SRC
fi

# make absolute WRAPPER_CONF
FIRST_CHAR=`echo $WRAPPER_CONF | cut -c1,1`
if [ "$FIRST_CHAR" != "/" ] ; then
    WRAPPER_CONF=$REAL_PATH/$WRAPPER_CONF
fi

#-----------------------------------------------------------------------------

# sevice process context / ID

ANCHOR_FILE="$PID_DIR/$APP_NAME.anchor"
STATUS_FILE="$PID_DIR/$APP_NAME.status"
JAVA_STATUS_FILE="$PID_DIR/$APP_NAME.java.status"
PID_FILE="$PID_DIR/$APP_NAME.pid"
LOCK_DIR="/var/lock/subsys"
LOCK_FILE="$LOCK_DIR/$APP_NAME"
pid=""

#-----------------------------------------------------------------------------

# Resolve the os
DIST_OS=`uname -s | tr [:upper:] [:lower:] | tr -d [:blank:]`

# wrapper bin naming conventions
case "$DIST_OS" in
    'sunos')
        DIST_OS="solaris"
        ;;
    'hp-ux' | 'hp-ux64')
        # HP-UX needs the XPG4 version of ps (for -o args)
        DIST_OS="hpux"
        UNIX95=""
        export UNIX95
        ;;
    'darwin')
        DIST_OS="macosx"
        ;;
    'unix_sv')
        DIST_OS="unixware"
        ;;
esac

# Resolve the architecture
if [ "$DIST_OS" = "macosx" ]
then
    DIST_ARCH="universal"
else
    DIST_ARCH=
    DIST_ARCH=`uname -p 2>/dev/null | tr [:upper:] [:lower:] | tr -d [:blank:]`
    if [ "X$DIST_ARCH" = "X" ]
    then
        DIST_ARCH="unknown"
    fi
    if [ "$DIST_ARCH" = "unknown" ]
    then
        DIST_ARCH=`uname -m 2>/dev/null | tr [:upper:] [:lower:] | tr -d [:blank:]`
    fi
    case "$DIST_ARCH" in
        'amd64' | 'athlon' | 'i386' | 'i486' | 'i586' | 'i686' | 'x86_64')
            DIST_ARCH="x86"
            ;;
        'ia32' | 'ia64' | 'ia64n' | 'ia64w')
            DIST_ARCH="ia"
            ;;
        'ip27')
            DIST_ARCH="mips"
            ;;
        'power' | 'powerpc' | 'power_pc' | 'ppc64')
            DIST_ARCH="ppc"
            ;;
        'pa_risc' | 'pa-risc')
            DIST_ARCH="parisc"
            ;;
        'sun4u' | 'sparcv9')
            DIST_ARCH="sparc"
            ;;
        '9000/800')
            DIST_ARCH="parisc"
            ;;
    esac
fi

outputFile() {
    if [ -f "$1" ]
    then
        log "  $1 (Found but not executable.)";
    else
        log "  $1"
    fi
}

# Decide on the wrapper binary "bitness" to use.

# TESTED: ubuntu, redhat

MACHINE_TYPE=`uname -m`

case ${MACHINE_TYPE} in
	'x86_64')
		DIST_BITS="64"
		;;
	*)
		DIST_BITS="32"
		;;
esac

#-----------------------------------------------------------------------------

exportJavaHome() {
	
	if [ "x$JAVA_HOME" = "x" ] && [ "$DIST_OS" = "macosx" ]; then
		JAVA_HOME=/System/Library/Frameworks/JavaVM.framework/Home
	fi

	if [ "x$JAVA_HOME" = "x" ] && [ "$DIST_OS" = "linux" ]; then
		JAVA_PATH="$(which "$JAVA_CMD")" 
		JAVA_REAL="$(readlink -f -n "$JAVA_PATH")"
		JAVA_HOME="$(dirname $(dirname "$JAVA_REAL"))"
	fi
			
    if [ "x$JAVA_HOME" = "x" ]; then
        log "error: unable to find JAVA_HOME"
        exit 1
    fi
    
    export JAVA_HOME
    
}

#-----------------------------------------------------------------------------

# wrapper bin naming convention

WRAPPER_SUFFIX="$DIST_OS-$DIST_ARCH-$DIST_BITS.bin"

WRAPPER_SRC="$WRAPPER_SRC-$WRAPPER_SUFFIX"
WRAPPER_CMD="$WRAPPER_CMD-$WRAPPER_SUFFIX"

#-----------------------------------------------------------------------------

# copy detected wrapper binary from dist into final location

if [ -x "$WRAPPER_CMD" ] ; then
	# file exists and executable
    : # log "found $WRAPPER_CMD"
else
    if [ -x "$WRAPPER_SRC" ] ; then
    	cp -f "$WRAPPER_SRC" "$WRAPPER_CMD"
    	if [ -x "$WRAPPER_CMD" ] ; then
	        : # log "copied $WRAPPER_CMD"
    	else
	        log "error: unable to use binaries:"
	        outputFile "$WRAPPER_SRC"
	        outputFile "$WRAPPER_CMD"
    	    exit 1
    	fi
    else
        log "error: unable to use binary:"
	        outputFile "$WRAPPER_SRC"
        exit 1
    fi
fi


#-----------------------------------------------------------------------------


# Build the nice clause
if [ "X$PRIORITY" = "X" ] ; then
    CMD_NICE=""
else
    CMD_NICE="nice -$PRIORITY"
fi


# Build the anchor file clause.
if [ "X$IGNORE_SIGNALS" = "X" ] ; then
   ANCHOR_PROP=
   IGNORE_PROP=
else
   ANCHOR_PROP=wrapper.anchorfile="\"$ANCHOR_FILE\""
   IGNORE_PROP="wrapper.ignore_signals=TRUE"
fi


# Build the status file clause.
if [ "X$DETAIL_STATUS" = "X" ] ; then
   STATUS_PROP=
else
   STATUS_PROP="wrapper.statusfile=\"$STATUS_FILE\" wrapper.java.statusfile=\"$JAVA_STATUS_FILE\""
fi


# Build the lock file clause.  Only create a lock file if the lock directory exists on this platform.
LOCK_PROP=
if [ -d $LOCK_DIR ] ; then
    if [ -w $LOCK_DIR ] ; then
        LOCK_PROP="wrapper.lockfile=\"$LOCK_FILE\""
    fi
fi


#-----------------------------------------------------------------------------

checkUserExists(){

    # log "checking if exists user: $RUN_AS_USER"
    RV=`$CMD_ID "$RUN_AS_USER"`
    if [ $? != 0 ] ; then
		log "error: user does not exist: $RUN_AS_USER"
		exit 1;
    fi

}

#
# note: recursion
#
checkUser() {

    # args:
    #	$1 touchLock flag (any non empty value)
    #	$2 command name from "usage: ..."

    # Check the configured user.
    if [ "X$RUN_AS_USER" != "X" ] ; then
        if [ "`$CMD_ID`" = "$RUN_AS_USER" ] ; then
            # Already running as the configured user.  Avoid password prompts by not calling su.
            RUN_AS_USER=""
        fi
    fi

    # Still want to change users, recurse.
    if [ "X$RUN_AS_USER" != "X" ] ; then

	log "currently script is running as user: `$CMD_ID`"
	log "switching to run as configured user: $RUN_AS_USER"

        # If LOCK_PROP and $RUN_AS_USER are defined then the new user will most likely not be
        # able to create the lock file.  The Wrapper will be able to update this file once it
        # is created but will not be able to delete it on shutdown.  If $2 is defined then
        # the lock file should be created for the current command
        if [ "X$LOCK_PROP" != "X" ] ; then
            if [ "X$1" != "X" ] ; then
                # Resolve the primary group
                RUN_AS_GROUP=`groups $RUN_AS_USER | awk '{print $3}' | tail -1`
                if [ "X$RUN_AS_GROUP" = "X" ] ; then
                    RUN_AS_GROUP=$RUN_AS_USER
                fi
                touch $LOCK_FILE
                chown $RUN_AS_USER:$RUN_AS_GROUP $LOCK_FILE
            fi
        fi

        # user will only be prompted for a password once.
        # variables shifted by 1.
        $CMD_SU - $RUN_AS_USER --command "\"$SCRIPT\" $2"

        # Now that we are the original user again, we may need to clean up the lock file.
        if [ "X$LOCK_PROP" != "X" ] ; then
            getpid
            if [ "X$pid" = "X" ] ; then
                # Wrapper is not running so make sure the lock file is deleted.
                if [ -f "$LOCK_FILE" ] ; then
                    rm -f "$LOCK_FILE"
                fi
            fi
        fi

		# terminate, since job was done in the recursive call
        exit 0

    fi
}

getpid() {
    pid=""
    if [ -f "$PID_FILE" ] ; then
        if [ -r "$PID_FILE" ] ; then
            pid=`cat "$PID_FILE"`
            if [ "X$pid" != "X" ] ; then
                # It is possible that 'a' process with the pid exists but that it is not the
                #	correct process.  This can happen in a number of cases, but the most
                #	common is during system startup after an unclean shutdown.
                # The ps statement below looks for the specific wrapper command running as
                #	the pid.  If it is not found then the pid file is considered to be stale.
                case "$DIST_OS" in
                    'macosx')
                        pidtest=`$EXE_PS -ww -p $pid -o command | grep "$WRAPPER_CMD" | tail -1`
                        ;;
                    *)
                        pidtest=`$EXE_PS -p $pid -o args | grep "$WRAPPER_CMD" | tail -1`
                        ;;
                esac

                if [ "X$pidtest" = "X" ] ; then
                    # This is a stale pid file.
                    rm -f "$PID_FILE"
                    log "Removed stale pid file: $PID_FILE"
                    pid=""
                fi
            fi
        else
            log "error: cannot read $PID_FILE."
            exit 1
        fi
    fi
}

getstatus() {

    STATUS=
    if [ -f "$STATUS_FILE" ] ; then
        if [ -r "$STATUS_FILE" ] ; then
            STATUS=`cat "$STATUS_FILE"`
        fi
    fi
    if [ "X$STATUS" = "X" ] ; then
        STATUS="Unknown"
    fi

    JAVA_STATUS=
    if [ -f "$JAVA_STATUS_FILE" ] ; then
        if [ -r "$JAVA_STATUS_FILE" ] ; then
            JAVA_STATUS=`cat "$JAVA_STATUS_FILE"`
        fi
    fi
    if [ "X$JAVA_STATUS" = "X" ] ; then
        JAVA_STATUS="Unknown"
    fi

}

testpid() {
    pid=`$EXE_PS -p $pid | grep $pid | grep -v grep | awk '{print $1}' | tail -1`
    if [ "X$pid" = "X" ] ; then
        # Process is gone so remove the pid file.
        rm -f "$PID_FILE"
        pid=""
    fi
}

console() {
    log "Running $APP_LONG_NAME ..."
    getpid
    if [ "X$pid" = "X" ] ; then
        # The string passed to eval must handle spaces in paths correctly.
        COMMAND_LINE="	\
        	$CMD_NICE \"$WRAPPER_CMD\" \"$WRAPPER_CONF\"	\
        	wrapper.syslog.ident=\"$APP_NAME\"	\
        	wrapper.pidfile=\"$PID_FILE\"	\
        	wrapper.name=\"$APP_NAME\"	\
        	wrapper.displayname=\"$APP_LONG_NAME\"	\
        	$ANCHOR_PROP $STATUS_PROP $LOCK_PROP	\
        	"
        eval $COMMAND_LINE
    else
        log "error: $APP_LONG_NAME is already running."
        exit 1
    fi
}

start() {
	#
    log "$APP_LONG_NAME is starting ..."
    getpid
    if [ "X$pid" = "X" ] ; then
        # The string passed to eval must handle spaces in paths correctly.
        COMMAND_LINE="	\
        	$CMD_NICE \"$WRAPPER_CMD\" \"$WRAPPER_CONF\"	\
        	wrapper.syslog.ident=\"$APP_NAME\"	\
        	wrapper.pidfile=\"$PID_FILE\"	\
        	wrapper.name=\"$APP_NAME\"	\
        	wrapper.displayname=\"$APP_LONG_NAME\"	\
        	wrapper.daemonize=TRUE	\
        	$ANCHOR_PROP $IGNORE_PROP $STATUS_PROP $LOCK_PROP	\
        	"
        eval $COMMAND_LINE
    else
        log "error: $APP_LONG_NAME is already running."
        exit 1
    fi
    #
    # Sleep for a few seconds to allow for intialization if required
    #  then test to make sure we're still running.
    if [ $WAIT_AFTER_STARTUP -gt 0 ] ; then
    	dot=" . "
	    count=0
	    while [ $count -lt $WAIT_AFTER_STARTUP ] ; do
	        echo -n $dot
	        sleep 1
	        count=`expr $count + 1`
	    done
	    echo $dot
    fi
    #
    # determinte run state
    getpid
    if [ "X$pid" = "X" ] ; then
        log "error: $APP_LONG_NAME may have failed to start."
        exit 1
    else
	    log "$APP_LONG_NAME is started; pid=$pid."
    fi

}

stopit() {

	# args
    # 	$1 exit if down flag

    log "$APP_LONG_NAME is stopping ..."

    getpid
    if [ "X$pid" = "X" ] ; then
        log "$APP_LONG_NAME was not running."
        if [ "X$1" = "X1" ] ; then
            exit 1
        fi
    else
        if [ "X$IGNORE_SIGNALS" = "X" ] ; then
            # Running so try to stop it.
            kill $pid
            if [ $? -ne 0 ] ; then
                # An explanation for the failure should have been given
                log "error: unable to stop $APP_LONG_NAME."
                exit 1
            fi
        else
            rm -f "$ANCHOR_FILE"
            if [ -f "$ANCHOR_FILE" ] ; then
                # An explanation for the failure should have been given
                log "error: unable to stop $APP_LONG_NAME."
                exit 1
            fi
        fi

        # We can not predict how long it will take for the wrapper to
        #  actually stop as it depends on settings in wrapper.conf.
        #  Loop until it does.
        savepid=$pid
        CNT=0
        TOTCNT=0
        while [ "X$pid" != "X" ] ; do
            # Show a waiting message every 5 seconds.
            if [ "$CNT" -lt "5" ] ; then
                CNT=`expr $CNT + 1`
            else
                log "waiting for $APP_LONG_NAME to exit..."
                CNT=0
            fi
            TOTCNT=`expr $TOTCNT + 1`
            sleep 1
            testpid
        done
        pid=$savepid
        testpid
        if [ "X$pid" != "X" ] ; then
            log "error: failed to stop $APP_LONG_NAME."
            exit 1
        else
            log "$APP_LONG_NAME is stopped"
        fi
    fi
}

status() {
    getpid
    if [ "X$pid" = "X" ] ; then
        log "error: $APP_LONG_NAME is not running"
        exit 1
    else
        if [ "X$DETAIL_STATUS" = "X" ] ; then
            log "$APP_LONG_NAME is running (PID:$pid)"
        else
            getstatus
            log "$APP_LONG_NAME is running (PID:$pid, Wrapper:$STATUS, Java:$JAVA_STATUS)"
        fi
        exit 0
    fi
}

dump() {
    log "dumping $APP_LONG_NAME ..."
    getpid
    if [ "X$pid" = "X" ] ; then
        log "$APP_LONG_NAME was not running."
    else
        kill -3 $pid
        if [ $? -ne 0 ] ; then
            log "error: failed to dump $APP_LONG_NAME"
            exit 1
        else
            log "dumped $APP_LONG_NAME"
        fi
    fi
}

# Used by HP-UX init scripts.
startmsg() {
    getpid
    if [ "X$pid" = "X" ] ; then
        log "starting $APP_LONG_NAME... (Wrapper:Stopped)"
    else
        if [ "X$DETAIL_STATUS" = "X" ] ; then
            log "starting $APP_LONG_NAME... (Wrapper:Running)"
        else
            getstatus
            log "starting $APP_LONG_NAME... (Wrapper:$STATUS, Java:$JAVA_STATUS)"
        fi
    fi
}

# Used by HP-UX init scripts.
stopmsg() {
    getpid
    if [ "X$pid" = "X" ] ; then
        log "stopping $APP_LONG_NAME... (Wrapper:Stopped)"
    else
        if [ "X$DETAIL_STATUS" = "X" ] ; then
            log "stopping $APP_LONG_NAME... (Wrapper:Running)"
        else
            getstatus
            log "stopping $APP_LONG_NAME... (Wrapper:$STATUS, Java:$JAVA_STATUS)"
        fi
    fi
}

##################################################

# test if running as root; needed by install/uninstall, enable/disable;
checkRoot() {
    if [ "`$CMD_ID`" != "root" ] ; then
		log "error: not a root; try to use 'sudo', 'su', 'runuser', etc."
		exit 1
    fi
}

# wrapper service link:
# TESTED: ubuntu, redhat
WRAPPER_SVC="/etc/init.d/$APP_NAME"

do_install(){
    ln --symbolic --force "$SCRIPT" "$WRAPPER_SVC"
	if [ $? -eq 0 ] ; then
		log "added: $WRAPPER_SVC"
    else
        log "error: failed to add: $WRAPPER_SVC"
        exit 1
    fi
    chmod 775 "$WRAPPER_SVC"
    chown --silent --recursive "$RUN_AS_USER":root "$REAL_PATH"
}

do_uninstall(){
	rm --force "$WRAPPER_SVC"
	if [ $? -eq 0 ] ; then
		log "removed: $WRAPPER_SVC"
    else
        log "error: failed to remove: $WRAPPER_SVC"
        exit 1
    fi
}

do_enable(){
	$CMD_SVC_ENABLE
	if [ $? -eq 0 ] ; then
		log "enabled: $WRAPPER_SVC"
    else
        log "error: failed to enable: $WRAPPER_SVC"
        exit 1
    fi
}

do_disable(){
	$CMD_SVC_DISABLE
	if [ $? -eq 0 ] ; then
		log "disabled: $WRAPPER_SVC"
    else
        log "error: failed to disable: $WRAPPER_SVC"
        exit 1
    fi
}

##################################################

#
# manager core; command executions:
#

# will terminate if java_home not found
exportJavaHome

# will terminate if user not found
checkUserExists

case "$1" in

    'console')
        checkUser touchlock $1
        console
        ;;

    'start')
        checkUser touchlock $1
        start
        ;;

    'stop')
        checkUser "" $1
        stopit "0"
        ;;

    'restart')
        checkUser touchlock $1
        stopit "0"
        sleep 1
        start
        ;;

    'condrestart')
        checkUser touchlock $1
        stopit "1"
        start
        ;;

    'status')
        checkUser "" $1
        status
        ;;

    'dump')
        checkUser "" $1
        dump
        ;;

    'start_msg')
        checkUser "" $1
        startmsg
        ;;

    'stop_msg')
        checkUser "" $1
        stopmsg
        ;;

#-----------------------------------------------------------------------------

    'install')
       	checkRoot
       	do_install
    	;;

    'uninstall')
    	checkRoot
    	do_uninstall
        ;;

    'enable')
    	checkRoot
    	do_enable
    	;;

    'disable')
    	checkRoot
    	do_disable
    	;;

#-----------------------------------------------------------------------------

    *)
        log "error: invalid command line;"
        log "usage: $0 { console | start | stop | restart | condrestart | status | dump | install | uninstall | enable | disable }"
        exit 1
        ;;

esac

exit 0

##################################################
