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

handle(docroot,urlroot)
	;
	; Template files handling.
	; 
	; Will parse and populate reponse("content") for any .html file present.  Anything else
	; will be passed to handle^static().
	;
	; Document root passed as in argument, as well as the "url root" for that document path,
	; default to  "/".  The  configured default file name is used if a directory is requested.
	;

	; Support GET and HEAD methods
	quit:'$$methodis^request("GET,HEAD")

	; Templates are pretty much handled like static file, so use static's getfile to
	; get the full file + pathname to the requested element.  An appropriate HTTP error
	; message will be set if the file isn't found.
	if '$data(urlroot) new urlroot set urlroot="/"
	new file
	set file=$$getfile^static(docroot,urlroot)
	quit:file=""

	; If file is not a .html, use handle^static()
	if $$FUNC^%UCASE($zparse(file,"TYPE"))'=".HTML" do handle^static(docroot,urlroot,file) quit

	; Parse the file to fill reponse("content") and get the last modified date.
	set response("content")=""
	new localvar
	set response("lastmod")=$$loadcontent(docroot,file)

	; Set response's content type
	set response("headers","Content-Type")="text/html"

	; Get md5sum of the generated content.
	new old,cmd,md5sum
	set old=$io
	set cmd="md5sum"
	open cmd:(command="md5sum -")::"PIPE"
	use cmd
	write response("content")
	write /eof
	read md5sum#32
	close cmd
	use old

	; If the client's cached copy is no valid, answer a 200 OK (response("content") is already populated).
	; Otherwise, kill the content so it is not sent.
	if '$$cacheisvalid^request(response("lastmod"),md5sum) do set^response(200)  if 1
	else  kill response("content")

	; Send Expires header to be 1 day later than current response's date.
	new expdate
	set expdate=$zpiece(response("date"),",",1)+1_","_$zpiece(response("date"),",",2)
	set response("headers","Expires")=$zdate(expdate,"DAY, DD MON YEAR 24:60:SS ")_"GMT"

	; Send Last-Modified header
	set response("headers","Last-Modified")=$zdate(response("lastmod"),"DAY, DD MON YEAR 24:60:SS ")_"GMT"

	; Send Accept-Range header
	set response("headers","Accept-Ranges")="none"

	; Send Cache-Control's max-age to be 1 day.
	set response("headers","Cache-Control")="max-age = 86400"

	; Send Content-MD5
	set response("headers","Content-MD5")=md5sum

	; Send an ETag
	set response("headers","ETag")=md5sum

	quit

loadcontent(docroot,file)
	;
	; Parse the file and fill reponse("content").
	;
	; Template language :
	;  <%include%file%/> : Replace the whole line with the content of 'file'.
	;     Example: <%include%/header.html%/>
	;  <%set%var=value%/> : Set a local variable value.  The whole line is dropped from output.
	;     Example: <%set%title=My Example Web Site%/>
	;  {%}var{%} : Replace the {%}...{%} string with the value of the local variable, if it exist.  In all case, the {%}...{%} string is dropped from output.
	;     Example: Welcome to {%}title{%}.
	;
	; Return the last modified date, which will be the latest one from all the
	; files accessed.
	;

	; Take the last modified date of the file.
	new cmd,old,buf,lastmod
	set old=$io
	set cmd="stat"
	open cmd:(command="stat -c %y "_file:readonly)::"PIPE"
	use cmd
	read buf
	close cmd
	set lastmod=$$CDN^%H($zextract(buf,6,7)_"/"_$zextract(buf,9,10)_"/"_$zextract(buf,1,4))_","_$$CTN^%H($zextract(buf,12,19))

	set response("filelist",file)=""
	; Read the file and fill response("content")
	new line,token,value,start,end
	open file:(readonly:chset="M")
	use file:width=1048576
	for  read line quit:$zeof  do
	.	set start=$zfind(line,"<%")
	.	if start=0 do
	.	.	for  quit:$zfind(line,"{%}")=0  do
	.	.	.	set line=$zpiece(line,"{%}",1)_$get(localvar($zpiece(line,"{%}",2)),"")_$zpiece(line,"{%}",3,$zlength(line))
	.	.	set response("content")=response("content")_line_delim
	.	else  do
	.	.	set end=$zfind(line,"%/>")
	.	.	if (end'=0)&(end>start) do
	.	.	.	set token=$zpiece(line,"%",2)
	.	.	.	set value=$zpiece(line,"%",3)
	.	.	.	if token="set" do
	.	.	.	.	set localvar($zpiece(value,"=",1))=$zpiece(value,"=",2,$zlength(line))
	.	.	.	else  if token="include" do
	.	.	.	.	new innerlastmod
	.	.	.	.	set innerlastmod=$$loadcontent(docroot,docroot_value)
	.	.	.	.	; Update last modified date if that included file is newer than the base file.
	.	.	.	.	set:$$isnewer^date(innerlastmod,lastmod) lastmod=innerlastmod
	close file
	use old

	; Return last modified date.
	quit lastmod
