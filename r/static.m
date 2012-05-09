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

	new ext,ct,old,cmd,length,curdate,expdate,lastmod,buf,md5sum
	set curdate=$horolog
	set response("headers","Date")=$zdate(curdate,"DAY, DD MON YEAR 24:60:SS ")

	; Get file last modified data, content-length, and md5sum.
	set old=$io
	set cmd="cmd"
	if connection("HTTPVER")'="HTTP/1.1" do
	.	open cmd:(command="du -b "_file:readonly)::"PIPE"
	.	use cmd
	.	read length
	.	close cmd
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

	if $data(request("headers","IF-MODIFIED-SINCE")) do
	.	new ifmod
	.	set ifmod=$$FUNC^%DATE($zextract(request("headers","IF-MODIFIED-SINCE"),6,7)_"/"_$zextract(request("headers","IF-MODIFIED-SINCE"),9,11)_"/"_$zextract(request("headers","IF-MODIFIED-SINCE"),13,16))_","_$$CTN^%H($zextract(request("headers","IF-MODIFIED-SINCE"),18,25))
	.	; If the file's last modification date is older than the if-modified-since date from the request header, send a "304 Not Modified" reponse.
	.	; Notice that in case the below condition is false, the else on the next line will be executed.
	.	if lastmod'>ifmod set response("status")="304"
	else  if $data(request("headers","IF-NONE-MATCH")),md5sum=request("headers","IF-NONE-MATCH") set response("status")="304"
	else  set response("status")="200" set:request("method")'="HEAD" response("file")=file

	; Get and send content-type
	set ext=$zparse(file,"TYPE")
	if $zlength(ext),$data(conf("ct",ext)) set ct=conf("ct",ext)
	else  do
	.	open cmd:(command="file --mime-type --brief --dereference --no-pad --preserve-date --special-files "_file:readonly)::"PIPE"
	.	use cmd
	.	read ct
	.	close cmd
	.	use old
	set response("headers","Content-Type")=ct

	; Let the client know which compression will be used, if any.
	if $data(request("headers","ACCEPT-ENCODING")) do
	.	; Send Vary header
	.	set response("headers","Vary")="Accept-Encoding"
	.	if $data(conf("compressible",ct)) do
	.	.	set:request("headers","ACCEPT-ENCODING")["compress" response("encoding")="compress"
	.	.	set:request("headers","ACCEPT-ENCODING")["gzip" response("encoding")="gzip"
	.	.	set:$data(response("encoding")) response("headers","Content-Encoding")=response("encoding")
	
	; Send chunked-encoding for HTTP/1.1, content-length for everyone else
	if connection("HTTPVER")="HTTP/1.1" do
	.	new encoding
	.	set encoding="chunked"
	.	; If TE advertise compression and we are not already using it, check if we can and advertise it if used.
	.	if '$data(response("encoding")),$data(request("headers","TE")) do
	.	.	write "Vary: TE"_eol
	.	.	if $data(conf("compressible",ct)) do
	.	.	.	set:request("headers","TE")["compress" response("encoding")="compress"
	.	.	.	set:request("headers","TE")["gzip" response("encoding")="gzip"
	.	.	.	set:$data(response("encoding")) encoding=encoding_", "_response("encoding")
	.	set response("headers","Transfer-Encoding")=encoding
	.	if 1
	else  set response("headers","Content-Length")=$zpiece(length,$char(9),1)

	; Send Expires header
	set expdate=$zpiece(curdate,",",1)+1_","_$zpiece(curdate,",",2)
	set response("headers","Expires")=$zdate(expdate,"DAY, DD MON YEAR 24:60:SS ")_"GMT"

	; Send Last-Modified header
	set response("headers","Last-Modified")=$zdate(lastmod,"DAY, DD MON YEAR 24:60:SS ")_"GMT"

	; Send Accept-Range header
	set response("headers","Accept-Ranges")="none"

	; Send Cache-Control header(s)
	set response("headers","Cache-Control")="max-age = 86400"

	; Send Content-MD5
	set response("headers","Content-MD5")=md5sum

	; Send an ETag
	set response("headers","ETag")=md5sum

	quit
