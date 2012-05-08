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
	do:$data(response("file")) sendfile(response("file"))

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

