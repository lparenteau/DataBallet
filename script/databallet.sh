#!/bin/bash

#
# This file is part of DataBallet.
# Copyright (C) 2012 Laurent Parenteau <laurent.parenteau@gmail.com>
#
# DataBallet is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# DataBallet is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with DataBallet. If not, see <http://www.gnu.org/licenses/>.
#

if [ "$2" != "" ] ; then
	configfile="$2"
else
	configfile="conf/default.conf"
fi

if [ ! -f $configfile ] ; then
	echo "Configuration file does not exist."
	exit 1
fi

source $configfile
progname="DataBallet"

function checkpid() {
	if [ -f $pid ] ; then
		ps -p `cat $pid` > /dev/null
		status="$?"
	else
		status="1"
	fi
}

function start() {
	echo "Starting $progname."
	checkpid
	if [ "0" = "$status" ] ; then
		echo "$progname is already running."
	else
		rm -f $pid
		echo "Starting $progname at " `date` " using $configfile." >> $log
		$gtm_dist/mupip rundown -r '*' >> $log 2>&1
		TZ="Europe/London" nohup $gtm_dist/mumps -run start^databallet < /dev/null >> $log 2>&1 &
		echo $! > $pid
	fi
}

function stop() {
	echo "Stoping $progname."
	checkpid
	if [ "0" = "$status" ] ; then
		# First, try a gentle stop
		$gtm_dist/mumps -run %XCMD 'do userconf^userconf set @TMP@("DataBallet","quit")=1'
		count=0
		checkpid
		while [ "0" = "$status" -a $count -lt 10 ]
		do
			sleep 1
			count=$(($count + 1))
			checkpid
		done
		# If still alive, force the process to stop
		if [ "0" = "$status" ] ; then
			$gtm_dist/mupip stop `cat $pid`
		fi
		echo "Stopped $progname at " `date` " using $configfile." >> $log
	else
		echo "$progname is not running."
	fi
	rm -f $pid
}

function status() {
	echo "Checking for $progname."
	checkpid
	if [ "0" = "$status" ] ; then
		echo "$progname is running."
	else
		echo "$progname is not running."
	fi
}

function update() {
	echo "Installing lastest code for $progname."
	tmpdir=`mktemp -d`
	cd $tmpdir
	wget https://github.com/lparenteau/$progname/tarball/master -O $progname.tar.gz
	tar -zxvf $progname.tar.gz
	cp -v lparenteau-$progname-*/r/*.m $gtmdir/r/
	cp -v lparenteau-$progname-*/script/* $gtmdir/script/
	cd -
	rm -Rf $tmpdir
}

case "$1" in
	start)
		start
		sleep 1
		status
		;;
	stop)
		stop
		;;
	restart)
		stop
		start
		sleep 1
		status
		;;
	status)
		status
		;;
	update)
		update
		stop
		start
		sleep 1
		status
		;;
	*)
		echo "Usage: $0 {start|stop|status|restart|update} <configfile>"
		exit 1
		;;
esac

exit 0
