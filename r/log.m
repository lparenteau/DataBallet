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

common()
	;
	; Output a Common Log Format entry for the current request/response to the log file.
	;
	new file,old,devices,msg
	zshow "D":devices
	set old=$io
	set file=conf("log")
	set msg=$zpiece($zpiece(devices("D",2),"=",4),"@",1)_" - - ["_$zdate(response("date"),"DD/MON/YEAR:24:60:SS ")_"+0000] """_request("method")_" "_request("uri")_" "_connection("HTTPVER")_""" "_response("status")_" "_$select($data(response("headers","Content-Length")):response("headers","Content-Length"),1:"0")
	do dolog()
	close file	
	use old
	quit

dolog()
	;
	; Open the chosen file and write the requested message
	;
	open file:(append:nofixed:wrap:noreadonly:chset="M")
	use file:exception="do retry"
	write msg,!
	quit

retry()
	; 
	; If the file has been updated between the open & write, retry again
	;
	zmessage:$zpiece($zstatus,",",3)'="%GTM-E-NOTTOEOFONPUT" +$zstatus
	close file
	do dolog()
	quit
