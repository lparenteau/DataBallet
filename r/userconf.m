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

conf()
	;
	; Initialize configuration with defaults if needed.
	;
	set:'$data(^httpm("conf","root")) ^httpm("conf","root")="/var/www/localhost/htdocs"
	set:'$data(^httpm("conf","log")) ^httpm("conf","log")=$ztrnlnm("gtm_log","","","","","VALUE")_"/httpm.log"
	set:'$data(^httpm("conf","index")) ^httpm("conf","index")="index.html"
	set:'$data(^httpm("conf","listen")) ^httpm("conf","listen")=8080
	set:'$data(^httpm("conf","server")) ^httpm("conf","server")="httpm"

	quit

