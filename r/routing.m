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

route()	;
	; Route the current request and populate the response
	;

	; First, check in the cache
	quit:$$serve^caching()

	; Find the correct route and handle the request
	new uri,host,handler
	set uri=request("uri")
	set host=$get(request("headers","HOST"),"*")
	set:'$data(conf("routing",host)) host="*"
	; Try to locate a handle fhe requested URI on the requested host.
	for i=$zlength(uri,"/"):-1:1 do  quit:$data(conf("routing",host,uri))
	.	set uri=$zpiece(uri,"/",1,i)
	.	set:uri="" uri="/"
	if $data(conf("routing",host,uri)) set handler=conf("routing",host,uri)
	; Otherwise, try that URI on the default host (ie. '*').
	else  do
	.	set host="*"
	.	for i=$zlength(uri,"/"):-1:1 do  quit:$data(conf("routing",host,uri))
	.	.	set uri=$zpiece(uri,"/",1,i)
	.	.	set:uri="" uri="/"
	.	set handler=conf("routing",host,uri)

	xecute handler

	; Cache the response
	do update^caching()

	quit 
