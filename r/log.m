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

start(commonfile,extfile)
	;
	; Start the log manager
	;
	new count,type,msg
	do userconf^userconf
	open:commonfile'="" commonfile:(append:nofixed:wrap:noreadonly:chset="M")
	if extfile'="" do
	.	open extfile:(append:nofixed:wrap:noreadonly:chset="M")
	.	use extfile
	.	write "#Version: 1.0",!
	.	write "#Date: "_$zdate($horolog,"DD-MON-YEAR 24:60:SS"),!
	.	write "#Fields: date time bytes cached c-ip s-dns cs-method cs-uri sc-status",!
	set @TMP@("DataBallet","log","count")=0
	for  do  quit:$data(@TMP@("DataBallet","quit"))
	.	if '$data(@TMP@("DataBallet","log","msg")) hang 1
	.	else  do
	.	.	set count=$order(@TMP@("DataBallet","log","msg",""))
	.	.	set type=$zextract(@TMP@("DataBallet","log","msg",count),1)
	.	.	if type="c",commonfile'="" use commonfile
	.	.	else  if type="e",extfile'="" use extfile
	.	.	else  set type="skip"
	.	.	write:type'="skip" $zextract(@TMP@("DataBallet","log","msg",count),2,$zlength(@TMP@("DataBallet","log","msg",count))),!
	.	.	kill @TMP@("DataBallet","log","msg",count)
	close:commonfile'="" commonfile
	close:extfile'="" extfile
	quit

log()
	;
	; Log the request/response
	;
	do common^log()
	do ext^log()
	quit

common()
	;
	; Output a Common Log Format entry for the current request/response to the log file.
	;
	; Common Log Format is "host ident authuser date request status bytes", with '-' for
	; missing data.
	;
	new msg
	set msg="c"_$$getcip^log()_" - - ["_$zdate(response("date"),"DD/MON/YEAR:24:60:SS ")_"+0000] """_request("method")_" "_request("uri")_" "_connection("HTTPVER")_""" "_response("status")_" "_$get(response("headers","Content-Length"),"0")
	do sendmsg^log(msg)
	quit

ext()
	;
	; Output an Extented Log Format entry for the current request/response to the log file.
	;
	; Extended Log Format is defined here : http://www.w3.org/TR/WD-logfile.html, but the
	; exact fields used can be read in start^log().
	;
	new msg
	set msg="e"_$zdate(response("date"),"DD-MON-YEAR 24:60:SS")_" "_$get(response("headers","Content-Length"),"0")_" "_$get(response("cached"),"0")_" "_$$getcip^log()_" "_$get(request("headers","HOST"),"*")_" "_request("method")_" "_request("uri")_" "_response("status")
	do sendmsg^log(msg)
	quit

sendmsg(msg)
	;
	; Send a msg to the log manager, maximum of 450 characters.
	;
	new cnt
	tstart ():serial
	set (cnt,@TMP@("DataBallet","log","count"))=@TMP@("DataBallet","log","count")+1
	tcommit
	set @TMP@("DataBallet","log","msg",cnt)=$zextract(msg,1,450)
	quit

getcip()
	;
	; Return the IP address of the connected client
	;
	new devices
	zshow "D":devices
	quit $zpiece($zpiece(devices("D",2),"=",4),"@",1)

