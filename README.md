# DataBallet

DataBallet is a web server and application framework implemented using the [M](https://en.wikipedia.org/wiki/MUMPS) language.  It is being developed and tested using [GT.M](http://fis-gtm.com/).

## Configuration

See conf/default.conf and modify it to suits your needs.  Better yet, copy, modify, and pass the new file as the second argument to script/databallet.sh.

## Starting the server

Start the server by executing `./script/databallet.sh start <configuration file>`.

## Stoping the server

Stop the server by executing `./script/databallet.sh stop <configuration file>`.

## Staying up to date

Once installed and working correctly, executing `./script/databallet.sh update <configuration file>` will get the latest scripts and source code from GitHub and restart the server.
