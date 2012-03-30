# HTTPM

HTTP server developed using GT.M.

## Configuring it

The following globals are required.

	^httpm("conf","root")		:	Fullpath to document root.  Default : "/var/www/localhost/htdocs/"
	^httpm("conf","index")		:	Default file name if a path is requested.  Default : "index.html"
	^httpm("conf","listen")		:	Port to listen on.  Default : 8080
	^httpm("conf","log")		:	Fullpath and file name for error log.  Default : "/tmp/httpm.log"
	^httpm("conf","server")		:	Server identification string.  Default : "httpm"

## Starting the server

Start the server by executing `./script/httpm.sh start`.

## Stoping the server

Stop the server by executing `./script/httpm.sh stop`.

