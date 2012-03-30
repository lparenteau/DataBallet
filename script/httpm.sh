#!/bin/sh

#
# httpm, an HTTP server developed using GT.M
# Copyright (C) 2012 Laurent Parenteau <laurent.parenteau@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

configfile="conf/httpm.conf"

if [ ! -f $configfile ] ; then
	echo "Configuration file does not exist."
	exit 1
fi

source $configfile
progname="httpm"

function checkpid() {
	if [ -f $pid ] ; then
		ps -p `cat $pid` > /dev/null
		status="$?"
	else
		status="1"
	fi
}

case "$1" in
	start)
		echo "Starting $progname."
		checkpid
		if [ "0" = "$status" ] ; then
			echo "$progname is already running."
		else
			rm -f $pid
			TZ="Europe/London" nohup $gtm_dist/mumps -run start^httpm < /dev/null > /dev/null 2>&1 &
			echo $! > $pid
		fi
		;;
	stop)
		echo "Stoping $progname."
		checkpid
		if [ "0" = "$status" ] ; then
			$gtm_dist/mupip stop `cat $pid`
		else
			echo "$progname is not running."
		fi
		rm -f $pid
		;;
	restart)
		$0 stop
		$0 start
		;;
	status)
		echo "Checking for $progname."
		checkpid
		if [ "0" = "$status" ] ; then
			echo "$progname is running."
		else
			echo "$progname is not running."
		fi
		;;
	*)
		echo "Usage: $0 {start|stop|status|restart}"
		exit 1
		;;
esac

exit 0
