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
	; Response handlers that implement a login/authentification interface.
	; 
	; docroot represent a directory containing some templates used to generate the various pages.
	; urlroot represent the url root that is being handled.  Will be used to create appropriate links.  Default to '/'
	;

	; Support GET, HEAD, PUT, and POST methods
	quit:'$$methodis^request("GET,HEAD,PUT,POST")
	
	; Default urlroot
	if '$data(urlroot) new urlroot set urlroot="/"

	if request("uri")=(urlroot_"login/") do login(docroot,urlroot)  if 1
	else  if request("uri")=(urlroot_"logout/") do logout(docroot,urlroot)  if 1
	; Everything else is 404 Not Found.
	else  do set^response(404) quit

	; Do not cache this.
	set response("headers","Cache-Control")="no-cache"

	; Get md5sum of the generated content.
	do md5sum^response()

	; Validate the cache
	do validatecache^request()

	quit

login(docroot,urlroot)
	;
	; Handle login page
	;

	; PUT/POST are for form submission.
	if $$methodis^request("PUT,POST") do postlogin(docroot,urlroot)  quit

	new localvar,lastmod
	set response("content")=""
	; Use template engine to load the header of the page.  Convention is to use '<docroot>/start.html', which can include a <title>{%}title{%}</title> line in there
	; to make use of ^AUTH("logintitle")
	set localvar("title")=$get(^AUTH("logintitle"))
	set response("lastmod")=$$loadcontent^template(docroot,docroot_"/start.html")

	; Set login form
	set response("content")=response("content")_"<h2>Login</h2><form action="""_urlroot_"login/"" method=""post"">"
	set response("content")=response("content")_"<p><label for=""username"">Username: </label><input type=""text"" name=""username"" /></p>"
	set response("content")=response("content")_"<p><label for=""password"">Password: </label><input type=""password"" name=""password"" /></p>"
	set response("content")=response("content")_"<p><input type=""submit"" value=""Login"" /></p>"
	set response("content")=response("content")_"</form>"

	; Use template engine to load the footer of the page.  Convention is to use '<docroot>/end.html'.
	set lastmod=$$loadcontent^template(docroot,docroot_"/end.html")
	; Update last modified date if needed.
	set:$$isnewer^date(lastmod,response("lastmod")) response("lastmod")=lastmod

	; Set response's content type
	set response("headers","Content-Type")="text/html"

	quit

postlogin(docroot,urlroot)
	;
	; Handle the login form data received
	;
	new content

	for i=1:1:2 do
	.	set value=$zpiece(request("content"),"&",i)
	.	set content($zpiece(value,"=",1))=$zpiece(value,"=",2,$zlength(line))

	new localvar,lastmod,session
	set response("content")=""
	; Use template engine to load the header of the page.  Convention is to use '<docroot>/start.html', which can include a <title>{%}title{%}</title> line in there
	; to make use of ^AUTH("logintitle")
	set localvar("title")=$get(^AUTH("logintitle"))
	set response("lastmod")=$$loadcontent^template(docroot,docroot_"/start.html")

	if $data(^AUTH("accounts",content("username"))) do  if 1
	.	if ^AUTH("accounts",content("username"),"password")=$$hash(content("password"),^AUTH("accounts",content("username"),"salt")) do
	.	.	set session=$$encode^base64($$salt(16))
	.	.	set response("content")=response("content")_"Welcome back "_content("username")_"!"
	.	.	set response("headers","Set-Cookie")="session="_session_"; Path=/; HttpOnly"
	.	.	set ^SESSION(session)=content("username")
	.	else  set response("content")=response("content")_"Wrong password..."
	else  set response("content")=response("content")_"Invalid username ."_content("username")_"."_$data(^AUTH("accounts",content("username")))

	; Use template engine to load the footer of the page.  Convention is to use '<docroot>/end.html'.
	set lastmod=$$loadcontent^template(docroot,docroot_"/end.html")
	; Update last modified date if needed.
	set:$$isnewer^date(lastmod,response("lastmod")) response("lastmod")=lastmod

	; Set response's content type
	set response("headers","Content-Type")="text/html"

	quit

logout(docroot,urlroot)
	;
	; Handle login page
	;

	new localvar,lastmod
	set response("content")=""
	; Use template engine to load the header of the page.  Convention is to use '<docroot>/start.html', which can include a <title>{%}title{%}</title> line in there
	; to make use of ^AUTH("logintitle")
	set localvar("title")=$get(^AUTH("logintitle"))
	set response("lastmod")=$$loadcontent^template(docroot,docroot_"/start.html")

	; Set login form
	set response("content")=response("content")_"<h2>Logged out!</h2>"
	set response("headers","Set-Cookie")="session=deleted; Path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT"
	kill ^SESSION($get(request("headers","COOKIE","session")," "))

	; Use template engine to load the footer of the page.  Convention is to use '<docroot>/end.html'.
	set lastmod=$$loadcontent^template(docroot,docroot_"/end.html")
	; Update last modified date if needed.
	set:$$isnewer^date(lastmod,response("lastmod")) response("lastmod")=lastmod

	; Set response's content type
	set response("headers","Content-Type")="text/html"

	quit

hash(value,salt)
	;
	; Hash value_salt
	;

	quit $$sha256^digest(value_salt)

salt(count)
	;
	; Return a pseudo-random value consisting of count digits.
	;
	new salt
	set salt=""

	for i=1:1:count set salt=salt_$random(10)

	quit salt
