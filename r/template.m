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
	quit:'$$methodis^request("GET,HEAD",1)

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
	new localvar
	set response("lastmod")=$$loadcontent(docroot,file)

	; Set response's content type
	set response("headers","Content-Type")="text/html"

	; Get md5sum of the generated content.
	do md5sum^response()

	; Validate the cache
	do validatecache^request()

	quit

loadcontent(docroot,file)
	;
	; Parse the file and fill reponse("content").
	;
	; Template language :
	;  <%include%file%/> : Replace the whole line with the content of 'file'.
	;     Example: <%include%/header.html%/>
	;  <%set%var=value%/> : Set a local variable value.  The whole line is dropped from output.
	;     Example: <%set%topic=Software%/>
	;     Example: <%set%title=My Example {%}topic{%} Web Site%/>
	;  {%}var{%} : Replace the {%}...{%} string with the value of the local variable, if it exist.  In all case, the {%}...{%} string is dropped from output.
	;     Example: Welcome to {%}title{%}.
	;  <%if%var=integer%/> : The whole line is dropped from the output.  If 'var' is different from 'integer', all lines until <%endif%/> are dropped.
	;  <%endif%/> : The whole line is dropped.
	;     Example:
	;	<%if%auth=1%/>
	;		Welcome {%}username{%}
	;		<%if%isadmin=1%/>
	;			You have access to the special <a href="/admin/">Admin</a> section!
	;		<%endif%/>
	;	<%endif%/>
	;     Note: If 'var' is undefined it defaults to 0.
	;  <%foreach%post%> :	The whole line is dropped from the output.  Text block will be repeated for all value of 'post'.
	;  <%endforeach%/> : The whole line is dropped
	;    Example:
	;      <%foreach%post%/>
	;        Post is titled {%}post,title{%}
	;      <%endforeach%/>
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

	set response("filelist",$order(response("filelist",""),-1)+1)=file
	; Read the file and fill response("content")
	new line,token,value,start,end,skip,foreach,count,lines,lncount,inloop,forskip
	set skip=0,foreach="",count=0,inloop=0,forskip=0
	open file:(readonly:chset="M")
	use file:width=1048576
innerloop ; Must use innerloop+3
	for  read line quit:$zeof  do
	.	set:foreach'="" lines(lncount)=line,lncount=lncount+1
	.	set start=$zfind(line,"<%")
	.	if start=0 do
	.	.	if (skip=0)&(forskip=0) do
	.	.	.	for  quit:$zfind(line,"{%}")=0  do
	.	.	.	.	new var
	.	.	.	.	if $zfind(line,",")=0 set var="localvar("""_$zpiece(line,"{%}",2)_""")"
	.	.	.	.	else  set var="localvar("""_$zpiece($zpiece(line,"{%}",2),",",1)_""","_count_","""_$zpiece($zpiece(line,"{%}",2),",",2)_""")"
	.	.	.	.	set line=$zpiece(line,"{%}",1)_$get(@var,"")_$zpiece(line,"{%}",3,$zlength(line))
	.	.	.	do addcontent^response(line_delim)
	.	else  do
	.	.	set end=$zfind(line,"%/>")
	.	.	if (end'=0)&(end>start) do
	.	.	.	set token=$zpiece(line,"%",2)
	.	.	.	set value=$zpiece(line,"%",3)
	.	.	.	if token="set" do:(skip=0)&(forskip=0)
	.	.	.	.	new varname
	.	.	.	.	set varname=$zpiece(value,"=",1)
	.	.	.	.	set line=$zpiece(line,"=",2,$zlength(line))
	.	.	.	.	set value=""
	.	.	.	.	for  quit:$zfind(line,"{%}")=0  do
	.	.	.	.	.	set value=value_$zpiece(line,"{%}",1)_localvar($zpiece(line,"{%}",2))
	.	.	.	.	.	set line=$zpiece(line,"{%}",3,$zlength(line))
	.	.	.	.	set value=value_$zpiece(line,"%",1)
	.	.	.	.	set localvar(varname)=value
	.	.	.	else  if token="if" do:(skip=0)&(forskip=0)
	.	.	.	.	set:$get(localvar($zpiece(value,"=",1)),0)'=$zpiece(value,"=",2,$zlength(line)) skip=skip+1
	.	.	.	else  if (token="endif")&(forskip=0) set:skip>0 skip=skip-1
	.	.	.	else  if token="foreach" do:(skip=0)&(forskip=0)
	.	.	.	.	set foreach=value
	.	.	.	.	set lncount=0
	.	.	.	.	set count=$order(localvar(foreach,""))
	.	.	.	.	if count="" set foreach="",forskip=forskip+1
	.	.	.	else  if token="endforeach" do:skip=0
	.	.	.	.	if foreach="" set:forskip>0 forskip=forskip-1
	.	.	.	.	else  set inloop=1
	.	.	.	else  if token="include" do:(skip=0)&(forskip=0)
	.	.	.	.	new innerlastmod
	.	.	.	.	set innerlastmod=$$loadcontent(docroot,docroot_value)
	.	.	.	.	; Update last modified date if that included file is newer than the base file.
	.	.	.	.	set:$$isnewer^date(innerlastmod,lastmod) lastmod=innerlastmod
	.	if inloop=1 do
	.	.	set lncount=$order(lines(lncount))
	.	.	if lncount'="" set line=lines(lncount) goto innerloop+3
	.	.	else  do
	.	.	.	set count=$order(localvar(foreach,count))
	.	.	.	if count="" set foreach="",inloop=0
	.	.	.	else  set lncount=0,line=lines(lncount),inloop=1 goto innerloop+3
	close file
	use old

	; Return last modified date.
	quit lastmod
