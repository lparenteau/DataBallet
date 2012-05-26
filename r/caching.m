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

update()
	;
	; Cache the current request's response
	;
	new host,uri,ae,te
	set host=$get(request("headers","HOST"),0)
	set uri=request("uri")
	set ae=$get(request("headers","ACCEPT-ENCODING"),0)
	set te=$get(request("headers","TE"),0)
	kill ^CACHE(host,uri,ae,te)
	merge ^CACHE(host,uri,ae,te)=response
	quit 

serve()
	;
	; Lookup and serve a response from the server's cache
	;
	; Return 1 and populate response if cache is OK.
	; Return 0 otherwise.
	;
	new host,uri,ae,te
	set host=$get(request("headers","HOST"),0)
	set uri=request("uri")
	set ae=$get(request("headers","ACCEPT-ENCODING"),0)
	set te=$get(request("headers","TE"),0)
	quit:'$data(^CACHE(host,uri,ae,te)) 0

	; Check if cached response is still valid, based on last modification of all files used to generate the original response.
	new file,cmd,old,buf,lastmod,curlastmod
	set file=$order(response("filelist",""))
	set cmd="stat"
	set old=$io
	set lastmod="0"
	for  quit:file=""  do
	.	open cmd:(command="stat -c %y "_file:readonly)::"PIPE"
	.	use cmd
	.	read buf
	.	close cmd
	.	set curlastmod=$$CDN^%H($zextract(buf,6,7)_"/"_$zextract(buf,9,10)_"/"_$zextract(buf,1,4))_","_$$CTN^%H($zextract(buf,12,19))
	.	set:curlastmod]lastmod lastmod=curlastmod
	use old
	quit:lastmod]^CACHE(host,uri,ae,te,"lastmod") 0

	; Load the response from cache.
	kill response
	merge response=^CACHE(host,uri,ae,te)
	do init^response()

	; Check if a 304 could be sent.  If so, remove the content.
	kill:$$cacheisvalid^request(response("lastmod"),response("headers","Content-MD5")) response("content")

	quit 1
