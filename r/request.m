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

gethttpver(line)
	;
	; Get the HTTP version from the request line.
	;
	quit $$FUNC^%UCASE($ztranslate($zpiece(line," ",3),$char(13)))

getmethod(line)
	;
	; Get the HTTP method from the request line.
	;
	quit $$FUNC^%UCASE($ztranslate($zpiece(line," ",1),$char(13)))

geturi(line)
	;
	; Parse the requested URI and get the requested entity from it.
	;
	quit $ztranslate($zpiece(line," ",2),$char(13))

parsehdrs(line)
	;
	; Read and parse a request header.  Will update 'request' or 'connection'.
	;
	new fieldname,value
	set fieldname=$ztranslate($$FUNC^%UCASE($zpiece(line," ",1)),":")
	set value=$ztranslate($zpiece(line," ",2,$zlength(line)),$char(13))
	; Use upper case value for HOST and CONNECTION header field, as those are looked at internally.
	set:(fieldname="HOST")!(fieldname="CONNECTION") value=$$FUNC^%UCASE(value)

	if fieldname="CONNECTION" set connection(fieldname)=value
	else  set request("headers",fieldname)=value

	quit

methodis(methods)
	;
	; Compare current request's method with the comma seperated list of methods.
	;
	new p
	for i=1:1 set p=$zpiece(methods,",",i,i) quit:(p="")!(p=request("method"))
	; Method is in the supplied list
	quit:p'="" 1
	; Method is not in the supplied list
	set response("status")="405"
	quit 0

cacheisvalid(lastmod,etag)
	;
	; Check if the client's cached element is still valid for this request.
	;

	; It is never valid if the client request no-cache.
	quit:$get(request("headers","CACHE-CONTROL"))="no-cache" 0

	new cacheisvalid
	set cacheisvalid=0
	if $get(request("headers","IF-NONE-MATCH"))=etag set response("status")="304" set cacheisvalid=1
	else  if $data(request("headers","IF-MODIFIED-SINCE")) do
	.	new ifmod
	.	set ifmod=$$FUNC^%DATE($zextract(request("headers","IF-MODIFIED-SINCE"),6,7)_"/"_$zextract(request("headers","IF-MODIFIED-SINCE"),9,11)_"/"_$zextract(request("headers","IF-MODIFIED-SINCE"),13,16))_","_$$CTN^%H($zextract(request("headers","IF-MODIFIED-SINCE"),18,25))
	.	; If the file's last modification date is older than the if-modified-since date from the request header, send a "304 Not Modified" reponse.
	.	if lastmod']ifmod set response("status")="304" set cacheisvalid=1

	quit cacheisvalid
