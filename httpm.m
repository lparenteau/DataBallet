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

conf
        ;
        ; Setup some HTTP constant mapping
        ;

        ; Status codes
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
        set ^httpm("status","502")="Bad Gateway"
        set ^httpm("status","503")="Service Unavailable"
        set ^httpm("status","504")="Gateway Timeout"
        set ^httpm("status","505")="HTTP Version Not Supported"

        ; Content-types
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

start
	;
	; Start the HTTP server.
	;
	do conf
	new socket,key,handle
	set socket="httpm"
	open socket:(ZLISTEN=^httpm("conf","listen")_":TCP":attach="httpm"):30:"SOCKET"
	use socket
	write /listen(5)
	for  do
	.	set key=""
	.	for  do  quit:key'=""
	.	.	write /wait(1)
	.	.	set key=$key
	.	; Spawn a new process to handle the connection then close the connected socket as we won't use it from here.
	.	set handle=$piece(key,"|",2)
	.	zsystem "$gtm_dist/mumps -run serve^httpm <&6 >&6 &"
	.	close socket:(socket=handle)
	.	use socket
	close socket
	quit

serve
	;
	; Server web page(s) to a connected client.
	;
	new line,httpver,eol,delim
	set eol=$char(13)_$char(10)
	set delim=$char(10)
	set timeout=10
	use $io:(nowrap:znodelay:delim=delim)
	read line:timeout
	if $test,'$zeof do
	.	set httpver=$$FUNC^%UCASE($ztranslate($zpiece(line," ",3),$char(13)))
	.	if httpver="HTTP/1.1" do serve11(line) if 1
	.	else  if httpver="HTTP/1.0" do serve10(line) if 1
	.	else  if httpver="" do serve09(line)
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
	quit:$$FUNC^%UCASE($zextract(line,1,4))'="GET "

	; Extract the Request-URI from the 1st line.
	new file
	set file=$$parseuri(line)

	; Ensure that the requested file exists and sits inside the document root.
	set dontcare=$zsearch("")
	quit:$zsearch(file)=""
	quit:$zextract(file,0,$zlength(^httpm("conf","root")))'=^httpm("conf","root")

	do sendfile(file)

	quit

serve10(line)
	;
	; Serve HTTP/1.0 requests.
	;
	set $x=0

	; Extract method
	new method
	set method=$$FUNC^%UCASE($zpiece(line," ",1))

	; Currently only support GET and HEAD methods
	if method'="GET",method'="HEAD" do senderr("501") quit

	; Extract the Request-URI
	new file
	set file=$$parseuri(line)

	; Ensure that the requested file exists and sits inside the document root.
	set dontcare=$zsearch("")
	if $zsearch(file)="" do senderr("404") quit
	if $zextract(file,0,$zlength(^httpm("conf","root")))'=^httpm("conf","root") do senderr("404") quit

	; Read all request
	new host,useragent,acceptencoding
	for  read line:timeout quit:'$test  quit:line=$char(13)  quit:$zeof  do
	.	set fieldname=$$FUNC^%UCASE($zpiece(line," ",1))
	.	if fieldname="HOST:" set host=$$FUNC^%UCASE($ztranslate($zpiece(line," ",2),$char(13)))
	.	else  if fieldname="USER-AGENT:" set useragent=$ztranslate($zpiece(line," ",2),$char(13))
	.	else  if fieldname="ACCEPT-ENCODING:" set acceptencoding=$ztranslate($zpiece(line," ",2),$char(13))
	.	else  if fieldname="CONNECTION:" set connection=$$FUNC^%UCASE($ztranslate($zpiece(line," ",2),$char(13)))
	quit:'$test
	quit:$zeof

	; Send response headers
	do sendstatus("200")
	do sendct(file)
	write eol

	quit:method="HEAD"
	do sendfile(file)

	quit

serve11(line)
	;
	; Server HTTP/1.1 requests
	;

	new connection
	set connection=""
	for  do serve10(line) quit:connection'="KEEP-ALIVE"  read line:timeout quit:'$test  quit:$zeof
	quit

senderr(status)
	do sendstatus(status)
	if $data(^httpm("status",status,"data")) write "Content-Type: "_^httpm("status","404","ct")_eol_eol_^httpm("status",status,"data") if 1
	else  write eol
	quit

sendstatus(status)
	write httpver_" "_status_" "_^httpm("status",status)_eol
	write "Date: "_$zdate($horolog,"DAY, DD MON YEAR 24:60:SS ")_^httpm("conf","timezone")_eol
	write "Server: httpm"_eol
	quit

sendct(file)
	new ext,ct
	set ext=$zparse(file,"TYPE")
	if $zlength(ext),$data(^httpm("ct",ext)) set ct=^httpm("ct",ext)
	else  set ct="text/plain"
	write "Content-Type: "_ct_eol
	quit

sendfile(file)
	; Read all content and send it.
	new old
	set old=$IO
	open file:(fixed:wrap:readonly:chset="M")
	for  use file read line:timeout quit:'$test  quit:$zeof  do
	.	use old
	.	write line
	.	set $x=0
	close file
	use old
	quit

parseuri(line)
	new file
	set file=$zparse(^httpm("conf","root")_$ztranslate($zpiece(line," ",2),$char(13)))
	if $zparse(file,"DIRECTORY")=file set file=file_^httpm("conf","index")
	quit file

