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

update()
	;
	; Cache the current request's response
	;

	; Check cache only if it is enabled
	quit:'$data(CACHE)
	; Cache only 200 OK
	quit:response("status")'=200
	; Do not cache if the response handler do not want us to
	quit:$get(response("headers","Cache-Control"))="no-cache"

	new host,uri,ae,te,cookie,cookies,hash
	set host=$get(request("headers","HOST"),0)
	set uri=request("uri")
	set ae=$get(request("headers","ACCEPT-ENCODING"),0)
	set te=$get(request("headers","TE"),0)
	set cookies=" "
	set cookie=$order(request("headers","COOKIE",""))
	for  quit:cookie=""  do
	.	set cookies=cookies_cookie_request("headers","COOKIE",cookie)
	.	set cookie=$order(request("headers","COOKIE",cookie))
	set hash=$$sha256^digest(uri_ae_te_cookies)
	kill @CACHE@(host,hash)
	merge @CACHE@(host,hash)=response
	quit 

serve()
	;
	; Lookup and serve a response from the server's cache
	;
	; Return 1 and populate response if cache is OK.
	; Return 0 otherwise.
	;

	; Check cache only if it is enabled
	quit:'$data(CACHE) 0

	; Check cache only for GET request
	quit:request("method")'="GET" 0

	new host,uri,ae,te,cookie,cookies,hash
	set host=$get(request("headers","HOST"),0)
	set uri=request("uri")
	set ae=$get(request("headers","ACCEPT-ENCODING"),0)
	set te=$get(request("headers","TE"),0)
	set cookies=" "
	set cookie=$order(request("headers","COOKIE",""))
	for  quit:cookie=""  do
	.	set cookies=cookies_cookie_request("headers","COOKIE",cookie)
	.	set cookie=$order(request("headers","COOKIE",cookie))
	set hash=$$sha256^digest(uri_ae_te_cookies)
	quit:'$data(@CACHE@(host,hash)) 0

	; Check if cached response is still valid, based on last modification of all files used to generate the original response.
	new file,cmd,old,buf,lastmod,curlastmod
	set file=$order(@CACHE@(host,hash,"filelist",""))
	set cmd="stat"
	set old=$io
	set lastmod="0"
	for  quit:file=""  do
	.	open cmd:(command="stat -c %y "_@CACHE@(host,hash,"filelist",file):readonly)::"PIPE"
	.	use cmd
	.	read buf
	.	close cmd
	.	set curlastmod=$$CDN^%H($zextract(buf,6,7)_"/"_$zextract(buf,9,10)_"/"_$zextract(buf,1,4))_","_$$CTN^%H($zextract(buf,12,19))
	.	set:$$isnewer^date(curlastmod,lastmod) lastmod=curlastmod
	.	set file=$order(@CACHE@(host,hash,"filelist",file))
	use old
	; Also, check for content based on globals.  Every global listed should contain a $H value, representing the last-modified date of
	; some global variable that was used to construct the response.
	new glo,now
	set glo=$order(@CACHE@(host,hash,"glolist",""))
	set now=$HOROLOG
	for  quit:glo=""  do
	.	set curlastmod=$get(@glo,now)
	.	set:$$isnewer^date(curlastmod,lastmod) lastmod=curlastmod
	.	set glo=$order(@CACHE@(host,hash,"glolist",glo))
	quit:$$isnewer^date(lastmod,@CACHE@(host,hash,"lastmod")) 0

	; Load the response from cache.
	kill response
	merge response=@CACHE@(host,hash)
	do init^response()
	set response("cached")=1

	; Validate the client's cache.
	do validatecache^request()

	quit 1
