	;
	; httpm, an HTTP server developed using GT.M
	; Copyright (C) 2012 Laurent Parenteau <laurent.parenteau@gmail.com>
	;
	; This program is free software: you can redistribute it and/or modify
	; it under the terms of the GNU Affero General Public License as published by
	; the Free Software Foundation, either version 3 of the License, or
	; (at your option) any later version.
	;
	; This program is distributed in the hope that it will be useful,
	; but WITHOUT ANY WARRANTY; without even the implied warranty of
	; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
	; GNU Affero General Public License for more details.
	;
	; You should have received a copy of the GNU Affero General Public License
	; along with this program. If not, see <http://www.gnu.org/licenses/>.
	;

conf()
	;
	; Required configuration
	;

	; User configuration.
	do envconf

	; HTTP status codes
	set ^httpm("status","100")="Continue"
	set ^httpm("status","101")="Switching Protocols"
	set ^httpm("status","200")="OK"
	set ^httpm("status","201")="Created"
	set ^httpm("status","202")="Accepted"
	set ^httpm("status","203")="Non-Authoritative Information"
	set ^httpm("status","204")="No Content"
	set ^httpm("status","205")="Reset Content"
	set ^httpm("status","206")="Partial Content"
	set ^httpm("status","300")="Multiple Choices"
	set ^httpm("status","301")="Moved Permanently"
	set ^httpm("status","302")="Found"
	set ^httpm("status","303")="See Other"
	set ^httpm("status","304")="Not Modified"
	set ^httpm("status","305")="Use Proxy"
	set ^httpm("status","307")="Temporary Redirect"
	set ^httpm("status","400")="Bad Request"
	set ^httpm("status","401")="Unauthorized"
	set ^httpm("status","402")="Payment Required"
	set ^httpm("status","403")="Forbidden"
	set ^httpm("status","404")="Not Found"
	set ^httpm("status","404","data")="<html><head><title>404 : Page Not Found</title></head><body><h1>404 : Page Not Found</h1></body></html>"
	set ^httpm("status","404","ct")="text/html"
	set ^httpm("status","404","cl")=$zlength(^httpm("status","404","data"))
	set ^httpm("status","405")="Method Not Allowed"
	set ^httpm("status","406")="Not Acceptable"
	set ^httpm("status","407")="Proxy Authentication Required"
	set ^httpm("status","408")="Request Timeout"
	set ^httpm("status","409")="Conflict"
	set ^httpm("status","410")="Gone"
	set ^httpm("status","411")="Length Required"
	set ^httpm("status","412")="Precondition Failed"
	set ^httpm("status","413")="Request Entity Too Large"
	set ^httpm("status","414")="Request-URI Too Long"
	set ^httpm("status","415")="Unsupported Media Type"
	set ^httpm("status","416")="Requested Range Not Satisfiable"
	set ^httpm("status","417")="Expectation Failed"
	set ^httpm("status","500")="Internal Server Error"
	set ^httpm("status","501")="Not Implemented"
	set ^httpm("status","501","data")="<html><head><title>501 : Functionnality Not Implemented</title></head><body><h1>501 : Functionnality Not Implemented</h1></body></html>"                            
	set ^httpm("status","501","ct")="text/html"                                                                                                                                                            
	set ^httpm("status","501","cl")=$zlength(^httpm("status","501","data"))
	set ^httpm("status","502")="Bad Gateway"
	set ^httpm("status","503")="Service Unavailable"
	set ^httpm("status","504")="Gateway Timeout"
	set ^httpm("status","505")="HTTP Version Not Supported"
	set ^httpm("status","505","data")="<html><head><title>505 : HTTP Version Not Supported</title></head><body><h1>505 : HTTP Version Not Supported</h1></body></html>"
	set ^httpm("status","505","ct")="text/html"
	set ^httpm("status","505","cl")=$zlength(^httpm("status","505","data"))

	; Content-types mapping
	set ^httpm("ct",".htm")="text/html"
	set ^httpm("ct",".html")="text/html"
	set ^httpm("ct",".css")="text/css"
	set ^httpm("ct",".xml")="text/xml"
	set ^httpm("ct",".js")="application/javascript"
	set ^httpm("ct",".jpg")="image/jpeg"
	set ^httpm("ct",".jpeg")="image/jpeg"
	set ^httpm("ct",".gif")="image/gif"
	set ^httpm("ct",".png")="image/png"

	quit

envconf()
	;
	; Configuration from environment variable
	;
	set conf("serverstring")=$ztrnlnm("httpm_server","","","","","VALUE")
	set conf("listenon")=$ztrnlnm("httpm_port","","","","","VALUE")
	set conf("docroot")=$ztrnlnm("httpm_docroot","","","","","VALUE")
	set conf("index")=$ztrnlnm("httpm_index","","","","","VALUE")
	set conf("errorlog")=$ztrnlnm("httpm_errorlog","","","","","VALUE")

	quit

start()
	;
	; Start the HTTP server.
	;
	set $ZTRAP="do errhandler^httpm"
	do conf
	new socket,key,handle,p,socketfd
	set socket="httpm"
	open socket:(ZLISTEN=conf("listenon")_":TCP":znoff:zdelay:zbfsize=2048:zibfsize=2048:attach="httpm"):30:"SOCKET"
	use socket
	write /listen(5)
	; When a connection will be made and the connected socket created, it will use the next number, so we can use that to
	; redirect stdin and stdout of the spawned mumps process so it is connected to that new socket.  This is needed until GT.M
	; support passing sockets to other processes directly.  Since the pipe device will create another two file descriptors,
	; the socket we want is actually the 3rd one at the end of the list.
	set p="ls"
	open p:(command="ls -1 /proc/"_$job_"/fd/ | tail -n 3 | head -n 1")::"PIPE"
	use p
	read socketfd
	close p
	use socket
	set socketfd=socketfd+1
	for  do
	.	set key=""
	.	for  do  quit:key'=""
	.	.	write /wait(1)
	.	.	set key=$key
	.	set handle=$piece(key,"|",2)
	.	; Spawn a new process to handle the connection then close the connected socket as we won't use it from here.
	.	zsystem "$gtm_dist/mumps -run serve^httpm <&"_socketfd_" >&"_socketfd_" 2>>"_conf("errorlog")_" &"
	.	close socket:(socket=handle)
	.	use socket
	close socket
	quit

serve()
	;
	; Server web page(s) to a connected client.
	;
	set $ZTRAP="do errhandler^httpm"
	do envconf
	new line,eol,delim,connection
	set eol=$char(13)_$char(10)
	set delim=$char(10)
	set timeout=10
	use $io:(nowrap:delim=delim:znoff:zdelay:zbfsize=2048:zibfsize=2048)
	read line:timeout
	if $test,'$zeof do
	.	set $x=0
	.	set connection("httpver")=$$gethttpver^request(line)
	.	if connection("httpver")="HTTP/1.1" set connection("connection")="CLOSE" do serve11(line) if 1
	.	else  if connection("httpver")="HTTP/1.0" do serve10(line) if 1
	.	else  if connection("httpver")="" do serve09(line) if 1
	.	else  do senderr^response("505") quit
	quit

serve09(line)
	;
	; Serve HTTP/0.9 requests.
	;
	; HTTP/0.9 supports only simple-request and simple-response :
	; Simple-Request  = "GET" SP Request-URI CRLF
	; Simple-Response = [ Entity-Body ]
	;

	; HTTP/0.9 only allow the GET method.
	quit:$$getmethod^request(line)'="GET"

	; Extract the Request-URI from the 1st line.
	new file
	set file=$$geturi^request(line)	

	; Ensure that the requested file exists and sits inside the document root.
	set dontcare=$zsearch("")
	quit:$zsearch(file)=""
	quit:$zextract(file,0,$zlength(conf("docroot")))'=conf("docroot")

	do sendfile^response(file)

	quit

serve10(line)
	;
	; Serve HTTP/1.0 requests.
	;
	new request

	; Extract method
	set request("method")=$$getmethod^request(line)

	; Currently only support GET and HEAD methods
	if request("method")'="GET",request("method")'="HEAD" do senderr^response("501") quit

	; Extract the Request-URI
	set request("file")=$$geturi^request(line)

	; Ensure that the requested file exists and sits inside the document root.
	set dontcare=$zsearch("")
	if $zsearch(request("file"))="" do senderr^response("404") quit
	if $zextract(request("file"),0,$zlength(conf("docroot")))'=conf("docroot") do senderr^response("404") quit

	; Read all request
	for  read line:timeout quit:'$test  quit:line=$char(13)  quit:$zeof  do parsehdrs^request(line)
	quit:'$test
	quit:$zeof

	; Send response headers
	do sendresphdr^response()

	; Send the content only if it isn't a HEAD request
	do:request("method")'="HEAD" sendfile^response(request("file"))

	quit

serve11(line)
	;
	; Server HTTP/1.1 requests
	;

	for  do serve10(line) quit:connection("connection")'="KEEP-ALIVE"  read line:timeout quit:'$test  quit:$zeof
	quit

errhandler()
	;
	; Error handler in case something bad happens.	Will print some debug information to the log file and halt.
	;

	set $ztrap="halt"
	new file,old
	set old=$io
	set file=conf("errorlog")
	open file:(append:nofixed:wrap:noreadonly:chset="M")
	use file
	write "Error at "_$horolog,!,$zstatus,!
	zshow "SDV"
	use old
	close file
	halt

