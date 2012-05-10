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

handle(docroot) ;
	; Static files handling
	;
	; Document root passed as in argument, and configured default file name
	; is used if a directory is requested.
	;

	; Support GET and HEAD methods
	quit:'$$methodis^request("GET,HEAD")

	; Ensure that the requested file exists and sits inside the document root.
	new dontcare,file
	set file=$zparse(docroot_request("uri"))
        if $zparse(file,"DIRECTORY")=file set file=file_conf("index")
	set dontcare=$zsearch("")
	if ($zsearch(file)="")!($zextract(file,0,$zlength(docroot))'=docroot) set response("status")="404" quit

	new old,cmd,expdate,lastmod,buf,md5sum

	; Get file last modified data and md5sum.
	set old=$io
	set cmd="cmd"
	open cmd:(command="stat -c %y "_file:readonly)::"PIPE"
	use cmd
	read buf
	close cmd
	open cmd:(command="md5sum "_file:readonly)::"PIPE"
	use cmd
	read md5sum#32
	close cmd
	use old
	set lastmod=$$CDN^%H($zextract(buf,6,7)_"/"_$zextract(buf,9,10)_"/"_$zextract(buf,1,4))_","_$$CTN^%H($zextract(buf,12,19))

	; If the client's cached copy is no valid, answer a 200 OK with for the file.
	if '$$cacheisvalid^request(lastmod,md5sum) set response("status")="200" set response("file")=file

	; Send Expires header to be 1 year later than current response's date.
	set expdate=$zpiece(response("date"),",",1)+1_","_$zpiece(response("date"),",",2)
	set response("headers","Expires")=$zdate(expdate,"DAY, DD MON YEAR 24:60:SS ")_"GMT"

	; Send Last-Modified header
	set response("headers","Last-Modified")=$zdate(lastmod,"DAY, DD MON YEAR 24:60:SS ")_"GMT"

	; Send Accept-Range header
	set response("headers","Accept-Ranges")="none"

	; Send Cache-Control's max-age to be 1 year.
	set response("headers","Cache-Control")="max-age = 86400"

	; Send Content-MD5
	set response("headers","Content-MD5")=md5sum

	; Send an ETag
	set response("headers","ETag")=md5sum

	quit
