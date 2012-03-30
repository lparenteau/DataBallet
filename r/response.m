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

sendresphdr(file)
	;
	; Send the response header for the supplied file
	;

	new ext,ct,old,du,length

	do sendstatus("200")

	; Get and send content-type
	set ext=$zparse(file,"TYPE")
	if $zlength(ext),$data(^httpm("ct",ext)) set ct=^httpm("ct",ext)
	else  set ct="text/plain"
	write "Content-Type: "_ct_eol

	; Get and send content-length
	set old=$io
	set du="du"
	open du:(command="du -b "_file:readonly)::"PIPE"
	use du
	read length
	use old
	close du
	write "Content-Length: ",$zpiece(length,$char(9),1),eol

	; HTTP mandate a blank line between headers and content.
	write eol
	quit

sendstatus(status)
	;
	; Send the stats line and basic header of an HTTP response
	;

	write connection("httpver")_" "_status_" "_^httpm("status",status)_eol
	write "Date: "_$zdate($horolog,"DAY, DD MON YEAR 24:60:SS ")_"GMT"_eol
	write:$data(^httpm("conf","server")) "Server: "_^httpm("conf","server")_eol
	quit

sendfile(file)
	;
	; Read all content of a file and send it.
	;

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

