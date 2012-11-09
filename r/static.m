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

handle(docroot,urlroot,file)
	;
	; Static files handling
	;
	; Document root passed as in argument, as well as the "url root" for that document path,
	; default to  "/".  The  configured default file name is used if a directory is requested.
	;
	; File is also an optional argument, which can contain the complete preprocessed path +
	; file name derived from request("uri").  If it isn't present, this handler will get it
	; itself from that request subscript.
	;

	; Support GET and HEAD methods
	quit:'$$methodis^request("GET,HEAD",1)

	; Get the path + file name.  An appropriate HTTP error message will be set if the file isn't found.
	if '$data(urlroot) new urlroot set urlroot="/"
	if '$data(file) new file set file=$$getfile(docroot,urlroot) quit:file=""

	set response("filelist",$order(response("filelist",""),-1)+1)=file
	set response("file")=file

	; Get file last modified date & md5sum.
	do md5sum^response()
	new old,cmd,buf
	set old=$io
	set cmd="cmd"
	open cmd:(command="stat -c %y "_file:readonly)::"PIPE"
	use cmd
	read buf
	close cmd
	use old
	set response("lastmod")=$$CDN^%H($zextract(buf,6,7)_"/"_$zextract(buf,9,10)_"/"_$zextract(buf,1,4))_","_$$CTN^%H($zextract(buf,12,19))

	; Validate the cache
	do validatecache^request()

	quit

getfile(docroot,urlroot)
	;
	; Get a path + file name from request("uri"), sitting in docroot, and considering that
	; docroot is represented by urlroot.
	;

	; Ensure that the requested file exists and sits inside the document root.
	new dontcare,file,d1,d2
	; Remove urlroot from requested URI so it points into docroot
	set file=$zparse(docroot_"/"_$zextract(request("uri"),$zlength(urlroot)+1,$zlength(request("uri"))))
	; If the target do not exist (file is empty) send a 404 not found.
	if file="" do set^response(404) quit file

	; If the request is a directory, but is missing the final "/", permanently redirect it to the correct location
	set d1=$zparse(file,"DIRECTORY")
	set d2=$zparse(file_"/","DIRECTORY")
	if (d1'=d2)&(d1'="")&(d2'="") do  if 1
	.	do set^response(301)
	.	set response("headers","Location")=request("uri")_"/"
	.	set file=""
	else  do
	.	; If the requested URI is a directory, use the default file.
	.	if d1=file set file=file_conf("index")
	.	; If the file doesn't exist, send a 404 not found.
	.	set dontcare=$zsearch("")
	.	if ($zsearch(file)="")!($zextract(file,0,$zlength(docroot))'=docroot) do set^response(404)  set file=""

	quit file
