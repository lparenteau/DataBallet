	;
	; httpm
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

	; Populate the response
	new response
	set response("status")=status

	if $data(conf("status",status,"data")) do
	.	set response("headers","Content-Type")=conf("status",status,"ct")
	.	set response("headers","Content-Length")=conf("status",status,"cl")

	; Send response headers
	do sendresphdr()

	; Headers end with a blank line
	write eol

	; Send error data, if any
	write:$data(conf("status",status,"data")) conf("status",status,"data")

	quit

sendresphdr()
	;
	; Send the response status and headers.
	;

	; Send the status line.
	write connection("HTTPVER")_" "_response("status")_" "_conf("status",response("status"))_eol

	; Send the Server header.
	write "Server: "_conf("serverstring")_eol

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

	; Handle Accept-Encoding compression
	if $data(request("headers","ACCEPT-ENCODING")) do
	.	set response("headers","Vary")="Accept-Encoding"
	.	if $data(conf("compressible",response("headers","Content-Type"))) do
	.	.	set:request("headers","ACCEPT-ENCODING")["compress" response("encoding")="compress"
	.	.	set:request("headers","ACCEPT-ENCODING")["gzip" response("encoding")="gzip"
	.	.	set:$data(response("encoding")) response("headers","Content-Encoding")=response("encoding")

	; Handle Transfer-Encoding, including chunked-encoding for HTTP/1.1 (content-length for everyone else)
	if connection("HTTPVER")="HTTP/1.1" do
	.	new encoding
	.	set encoding="chunked"
	.	; If TE advertise compression and we are not already using it, check if we can and advertise it if used.
	.	if '$data(response("encoding")),$data(request("headers","TE")) do
	.	.	write "Vary: TE"_eol
	.	.	if $data(conf("compressible",response("headers","Content-Type"))) do
	.	.	.	set:request("headers","TE")["compress" response("encoding")="compress"
	.	.	.	set:request("headers","TE")["gzip" response("encoding")="gzip"
	.	.	.	set:$data(response("encoding")) encoding=encoding_", "_response("encoding")
	.	set response("headers","Transfer-Encoding")=encoding
	.	if 1
	else  do
	.	new length
	.	if $data(response("file")) do
	.	.	new cmd,old
	.	.	set cmd="du"
	.	.	set old=$io
	.	.	open cmd:(command="du -b "_response("file"):readonly)::"PIPE"
	.	.	use cmd
	.	.	read length
	.	.	close cmd
	.	.	set length=$zpiece(length,$char(9),1)
	.	.	if 1
	.	else  set length=$zlength(response("content"))
	.	set response("headers","Content-Length")=$zpiece(length,$char(9),1)

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
	.	else  sendcontent(response("content"))

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
	.	write:connection("HTTPVER")="HTTP/1.1" $$FUNC^%DH($zlength(line),1),eol
	.	write line
	.	write:connection("HTTPVER")="HTTP/1.1" eol
	.	set $x=0
	close file
	use old
	write:connection("HTTPVER")="HTTP/1.1" "0",eol,eol
	quit

sendcontent(data)
	;
	; Send supplied data as content
	;
	write:connection("HTTPVER")="HTTP/1.1" $$FUNC^%DH($zlength(data),1),eol
	write data
	write:connection("HTTPVER")="HTTP/1.1" eol
	set $x=0
	write:connection("HTTPVER")="HTTP/1.1" "0",eol,eol
	quit

init()
	;
	; Initialiaze the response headers
	;
	set response("date")=$horolog
	set response("headers","Date")=$zdate(response("date"),"DAY, DD MON YEAR 24:60:SS ")
