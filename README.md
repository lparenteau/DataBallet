# HTTPM

HTTP server developed using GT.M.

## Configuring it

### User configuration

The following globals are required (some configuration utility will goes in eventually).

	^httpm("conf","root")		:	Fullpath to document root.  Example : "/var/www/localhost/htdocs/"
	^httpm("conf","index")		:	Default file name if a path is requested.  Example : "index.html"
	^httpm("conf","listen")		:	Port to listen on.  Example : 8080
	^httpm("conf","host")		:	Server's hostname (or virtual hostname).  Example : "localhost"
	^httpm("conf","timezone")	:	Server's timezone.  Example : "EDT"

### Initial setup

The first time you run the server, and after any upgrade, you have to setup some internal configuration.

	$gtm_dist/mumps -run conf^httpm

## Using it

Start the server by executing stat^httpm.

	$gtm_dist/mumps -run start^httpm

To stop the server, press CTRL-C in the terminal where the server is running then `halt` it.
