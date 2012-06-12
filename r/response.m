	;
	; This file is part of DataBallet.
	; Copyright (C) 2012 Laurent Parenteau <laurent.parenteau@gmail.com>
	;
	; DataBallet is free software: you can redistribute it and/or modify
	; it under the terms of the GNU Affero General Public License as published by
	; the Free Software Foundation, either version 3 of the License, or
	; (at your option) any later version.
	;
	; DataBallet is distributed in the hope that it will be useful,
	; but WITHOUT ANY WARRANTY; without even the implied warranty of
	; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
	; GNU Affero General Public License for more details.
	;
	; You should have received a copy of the GNU Affero General Public License
	; along with DataBallet. If not, see <http://www.gnu.org/licenses/>.
	;

set(status)
	;
	; Fill the current response with default stuff for the requested status
	;
	set response("status")=status

	if $data(conf("status",status,"data")) do
	.	set response("headers","Content-Type")=conf("status",status,"ct")
	.	set response("headers","Content-Length")=conf("status",status,"cl")
	.	set response("content")=conf("status",status,"data")

	quit

senderr(status)
	;
	; Send an HTTP error response
	;

	; Populate the response
	new response

	do set^response(status)

	; Send response headers
	do sendresphdr()

	; Headers end with a blank line
	write eol

	; Send error data, if any
	write:$data(response("content")) response("content")

	; Log request/response
	set:'$data(response("date")) response("date")=$horolog
	set:'$data(request("method")) request("method")=""
	set:'$data(request("uri")) request("uri")=""
	do common^log()

	quit

sendresphdr()
	;
	; Send the response status and headers.
	;

	; Set content-type for file, if needed
	if $data(response("file")) do
	.	new ext,ct
	.	set ext=$zparse(response("file"),"TYPE")
	.	if $zlength(ext),$data(conf("ct",ext)) set ct=conf("ct",ext)
	.	else  do
	.	.	new cmd,old
	.	.	set cmd="file"
	.	.	set old=$io
	.	.	open cmd:(command="file --mime-type --brief --dereference --no-pad --preserve-date --special-files "_response("file"):readonly)::"PIPE"
	.	.	use cmd
	.	.	read ct
	.	.	close cmd
	.	.	use old
	.	set response("headers","Content-Type")=ct

	if $data(response("headers","Content-Type")) do
	.	; Handle Accept-Encoding compression
	.	if $data(request("headers","ACCEPT-ENCODING")) do
	.	.	set response("headers","Vary")="Accept-Encoding"
	.	.	if $data(conf("compressible",response("headers","Content-Type"))) do
	.	.	.	set:request("headers","ACCEPT-ENCODING")["compress" response("encoding")="compress"
	.	.	.	set:request("headers","ACCEPT-ENCODING")["gzip" response("encoding")="gzip"
	.	.	.	set:$data(response("encoding")) response("headers","Content-Encoding")=response("encoding")
	.	; Handle Transfer-Encoding, including chunked-encoding for HTTP/1.1 (content-length for everyone else)
	.	if connection("HTTPVER")="HTTP/1.1" do
	.	.	new encoding
	.	.	set encoding="chunked"
	.	.	; If TE advertise compression and we are not already using it, check if we can and advertise it if used.
	.	.	if '$data(response("encoding")),$data(request("headers","TE")) do
	.	.	.	write "Vary: TE"_eol
	.	.	.	if $data(conf("compressible",response("headers","Content-Type"))) do
	.	.	.	.	set:request("headers","TE")["compress" response("encoding")="compress"
	.	.	.	.	set:request("headers","TE")["gzip" response("encoding")="gzip"
	.	.	.	.	set:$data(response("encoding")) encoding=encoding_", "_response("encoding")
	.	.	set response("headers","Transfer-Encoding")=encoding
	.	.	if 1
	.	else  do
	.	.	new length
	.	.	if $data(response("file")) do
	.	.	.	new cmd,old
	.	.	.	set cmd="du"
	.	.	.	set old=$io
	.	.	.	open cmd:(command="du -b "_response("file"):readonly)::"PIPE"
	.	.	.	use cmd
	.	.	.	read length
	.	.	.	close cmd
	.	.	.	set length=$zpiece(length,$char(9),1)
	.	.	.	if 1
	.	.	else  set:$data(response("content")) length=$zlength(response("content"))
	.	.	set:$data(length) response("headers","Content-Length")=length
	set:$data(response("lastmod")) response("headers","Last-Modified")=$zdate(response("lastmod"),"DAY, DD MON YEAR 24:60:SS ")_"GMT"

	; Send the status line.
	write connection("HTTPVER")_" "_response("status")_" "_conf("status",response("status"))_eol

	; Send all headers present in the response.
	new header
	set header=$order(response("headers",""))
	for  quit:header=""  do
	.	write header_": "_response("headers",header)_eol
	.	set header=$order(response("headers",header))

	; Headers end with a blank line
	write eol

	quit

send()
	;
	; Send content
	;

	; If a file has been specified, send it.
	if request("method")'="HEAD" do
	.	if $data(response("file")) do sendfile(response("file")) if 1
	.	else  do:$data(response("content")) sendcontent(response("content"))

	; Log request/response
	do common^log()

	quit

sendfile(filename)
	;
	; Read all content of a file and send it.  If compression was advertised, compress the file before sending it.
	;

	new old,line,file,length
	set length=0
	set old=$IO
	if $data(response("encoding")) do
	.	set file="cmd"
	.	open file:(command=response("encoding")_" -c "_filename:fixed:wrap:readonly)::"PIPE"
	.	if 1
	else  set file=filename open file:(fixed:wrap:readonly:chset="M")
	for  use file read line:timeout quit:'$test  quit:$zeof  do
	.	use old
	.	write:connection("HTTPVER")="HTTP/1.1" $$FUNC^%DH($zlength(line),1),eol
	.	write line
	.	set length=length+$zlength(line)
	.	write:connection("HTTPVER")="HTTP/1.1" eol
	.	set $x=0
	close file
	use old
	write:connection("HTTPVER")="HTTP/1.1" "0",eol,eol
	set:'$data(response("headers","Content-Length")) response("headers","Content-Length")=length
	quit

sendcontent(data)
	;
	; Send supplied data as content
	;

	if $data(response("encoding")) do
	.	new cmd,old,arg
	.	set old=$io
	.	set cmd="encoding"
	.	if response("encoding")="gzip" set arg=" -f"
	.	else  set arg=""
	.	; The exception handling is a workaround required until GTM-7351 gets fixed.
	.	open cmd:(exception="new dontcare":command=response("encoding")_arg:fixed:wrap)::"PIPE"
	.	use cmd
	.	write data
	.	write /eof
	.	read data
	.	close cmd
	.	use old
	write:connection("HTTPVER")="HTTP/1.1" $$FUNC^%DH($zlength(data),1),eol
	write data
	write:connection("HTTPVER")="HTTP/1.1" eol
	set $x=0
	write:connection("HTTPVER")="HTTP/1.1" "0",eol,eol
	set:'$data(response("headers","Content-Length")) response("headers","Content-Length")=$zlength(data)
	quit

init()
	;
	; Initialiaze the response headers
	;
	new expdate
	set response("date")=$horolog
	set response("headers","Date")=$zdate(response("date"),"DAY, DD MON YEAR 24:60:SS ")_"GMT"
	set response("headers","Server")="DataBallet"
	set response("headers","Accept-Ranges")="none"
	set:$get(conf("serverstring"))="full" response("headers","Server")=response("headers","Server")_"-"_databalletver_" ("_$zversion_")"
	set expdate=$zpiece(response("date"),",",1)+1_","_$zpiece(response("date"),",",2)
	set response("headers","Expires")=$zdate(expdate,"DAY, DD MON YEAR 24:60:SS ")_"GMT"
	set response("headers","Cache-Control")="max-age = 86400"
	quit

md5sum()
	;
	; Calculate the MD5SUM of the response's content (or file)
	;
	new old,cmd,file
	set old=$io
	set cmd="md5sum"
	set file=$get(response("file"),"-")
	open cmd:(command="md5sum "_file)::"PIPE"
	use cmd
	if '$data(response("file")) do
	.	write response("content")
	.	write /eof
	read response("headers","Content-MD5")#32
	close cmd
	use old

	; Set ETag
	set response("headers","ETag")=response("headers","Content-MD5")

	quit
