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

senderr(status)
	;
	; Send an HTTP error response
	;
	do sendstatus(status)
	if '$data(^httpm("status",status,"data")) write eol
	else  do
	.	write "Content-Type: "_^httpm("status",status,"ct")_eol
	.	write "Content-Length: "_^httpm("status",status,"cl")_eol
	.	write eol_^httpm("status",status,"data")
	quit

sendresphdr()
	;
	; Send the response header for the current request.
	;
	new ext,ct,old,cmd,length,curdate,expdate,lastmod,buf,md5sum
	set curdate=$horolog

	; Get file last modified data, content-length, and md5sum.
	set old=$io
	set cmd="cmd"
	if connection("httpver")'="HTTP/1.1" do
	.	open cmd:(command="du -b "_request("file"):readonly)::"PIPE"
	.	use cmd
	.	read length
	.	close cmd
	open cmd:(command="stat -c %y "_request("file"):readonly)::"PIPE"
	use cmd
	read buf
	close cmd
	open cmd:(command="md5sum "_request("file"):readonly)::"PIPE"
	use cmd
	read md5sum#32
	close cmd
	use old
	set lastmod=$$CDN^%H($zextract(buf,6,7)_"/"_$zextract(buf,9,10)_"/"_$zextract(buf,1,4))_","_$$CTN^%H($zextract(buf,12,19))

	if $data(request("if-modified-since")) do
	.	new ifmod
	.	set ifmod=$$FUNC^%DATE($zextract(request("IF-MODIFIED-SINCE"),6,7)_"/"_$zextract(request("IF-MODIFIED-SINCE"),9,11)_"/"_$zextract(request("IF-MODIFIED-SINCE"),13,16))_","_$$CTN^%H($zextract(request("IF-MODIFIED-SINCE"),18,25))
	.	; If the file's last modification date is older than the if-modified-since date from the request header, send a "304 Not Modified" reponse.
	.	; Notice that in case the below condition is false, the else on the next line will be executed.
	.	if lastmod'>ifmod do sendstatus("304") if 1
	else  if $data(request("IF-NONE-MATCH")),md5sum=request("IF-NONE-MATCH") do sendstatus("304") if 1
	else  do sendstatus("200")

	; Get and send content-type
	set ext=$zparse(request("file"),"TYPE")
	if $zlength(ext),$data(^httpm("ct",ext)) set ct=^httpm("ct",ext)
	else  set ct="text/plain"
	write "Content-Type: "_ct_eol

	; Let the client know which compression will be used, if any.
	if $data(request("ACCEPT-ENCODING")) do
	.	; Send Vary header
	.	write "Vary: Accept-Encoding"_eol
	.	if $data(^httpm("compressible",ct)) do
	.	.	set:request("ACCEPT-ENCODING")["compress" response("encoding")="compress"
	.	.	set:request("ACCEPT-ENCODING")["gzip" response("encoding")="gzip"
	.	.	write:$data(response("encoding")) "Content-Encoding: "_response("encoding")_eol

	; Send chunked-encoding for HTTP/1.1, content-length for everyone else
	if connection("httpver")="HTTP/1.1" do
	.	new encoding
	.	set encoding="chunked"
	.	; If TE advertise compression and we are not already using it, check if we can and advertise it if used.
	.	if '$data(response("encoding")),$data(request("TE")) do
	.	.	write "Vary: TE"_eol
	.	.	if $data(^httpm("compressible",ct)) do
	.	.	.	set:request("TE")["compress" response("encoding")="compress"
	.	.	.	set:request("TE")["gzip" response("encoding")="gzip"
	.	.	.	set:$data(response("encoding")) encoding=encoding_", "_response("encoding")
	.	write "Transfer-Encoding: "_encoding_eol
	.	if 1
	else  write "Content-Length: ",$zpiece(length,$char(9),1),eol

	; Send Expires header
	set expdate=$zpiece(curdate,",",1)+1_","_$zpiece(curdate,",",2)
	write "Expires: "_$zdate(expdate,"DAY, DD MON YEAR 24:60:SS ")_"GMT"_eol

	; Send Last-Modified header
	write "Last-Modified: "_$zdate(lastmod,"DAY, DD MON YEAR 24:60:SS ")_"GMT"_eol

	; Send Accept-Range header
	write "Accept-Ranges: none"_eol

	; Send Cache-Control header(s)
	write "Cache-Control: max-age = 86400"_eol

	; Get and send Content-MD5
	write "Content-MD5: "_md5sum_eol

	; Send an ETag
	write "ETag: "_md5sum_eol

	; HTTP mandate a blank line between headers and content.
	write eol
	quit

sendstatus(status)
	;
	; Send the stats line and basic header of an HTTP response
	;
	if '$data(curdate) new curdate set curdate=$horolog
	set:$data(response) response("status")=status
	write connection("httpver")_" "_status_" "_^httpm("status",status)_eol
	write "Date: "_$zdate(curdate,"DAY, DD MON YEAR 24:60:SS ")_"GMT"_eol
	write "Server: "_conf("serverstring")_eol
	quit

sendfile(filename)
	;
	; Read all content of a file and send it.  If compression was advertised, compress the file before sending it.
	;
	new old,line,file
	set old=$IO
	if $data(response("encoding")) do
	.	set file="cmd"
	.	open file:(command=response("encoding")_" -c "_filename:fixed:wrap:readonly)::"PIPE"
	.	if 1
	else  set file=filename open file:(fixed:wrap:readonly:chset="M")
	for  use file read line:timeout quit:'$test  quit:$zeof  do
	.	use old
	.	write:connection("httpver")="HTTP/1.1" $$FUNC^%DH($zlength(line),1),eol
	.	write line
	.	write:connection("httpver")="HTTP/1.1" eol
	.	set $x=0
	close file
	use old
	write:connection("httpver")="HTTP/1.1" "0",eol,eol
	quit

