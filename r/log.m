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

start(commonfile)
	;
	; Start the log manager
	;
	new count
	do userconf^userconf
	open commonfile:(append:nofixed:wrap:noreadonly:chset="M")
	use commonfile
	set @TMP@("DataBallet","commonlog","count")=0
	for  do  quit:$data(@TMP@("DataBallet","quit"))
	.	if '$data(@TMP@("DataBallet","commonlog","msg")) hang 1
	.	else  do
	.	.	set count=$order(@TMP@("DataBallet","commonlog","msg",""))
	.	.	write @TMP@("DataBallet","commonlog","msg",count),!
	.	.	kill @TMP@("DataBallet","commonlog","msg",count)
	close commonfile
	quit

common()
	;
	; Output a Common Log Format entry for the current request/response to the log file.
	;
	new devices,msg,cnt
	zshow "D":devices
	set msg=$zextract($zpiece($zpiece(devices("D",2),"=",4),"@",1)_" - - ["_$zdate(response("date"),"DD/MON/YEAR:24:60:SS ")_"+0000] """_request("method")_" "_request("uri")_" "_connection("HTTPVER")_""" "_response("status")_" "_$get(response("headers","Content-Length"),"0"),1,450)
	tstart ():serial
	set (cnt,@TMP@("DataBallet","commonlog","count"))=@TMP@("DataBallet","commonlog","count")+1
	tcommit
	set @TMP@("DataBallet","commonlog","msg",cnt)=msg
	quit
