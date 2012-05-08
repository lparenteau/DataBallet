	;
	; httpm, an HTTP server developed using GT.M
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

	new uri,host,handler
	set uri=request("uri")
	set host=$select($data(request("headers","HOST")):request("headers","HOST"),1:"*")
	set:'$data(conf("routing",host)) host=$select($data(conf("routing","*")):"*",1:"")
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

	quit 
