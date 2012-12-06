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

handle(docroot,urlroot,AUTH)
	;
	; Response handlers that implement a login/authentification interface.
	; 
	; docroot represent a directory containing some templates used to generate the various pages.
	; urlroot represent the url root that is being handled.  Will be used to create appropriate links.  Default to '/'
	; AUTH alias pointing to the global to use to store credentials.
	;

	; Support GET, HEAD, PUT, and POST methods
	quit:'$$methodis^request("GET,HEAD,PUT,POST",1)
	
	; If the connection is not secure, redirect to get a secure connection
	if '$$issecure^connection() do  quit
	.	if '$data(request("headers","HOST")) do set^response(401)  if 1
	.	else  do set^response(301)  set response("headers","Location")="https://"_$zpiece(request("headers","HOST"),":",1)_request("uri")

	; Default urlroot
	if '$data(urlroot) new urlroot set urlroot="/"
	; Default AUTH
	if '$data(AUTH) new AUTH set AUTH="^AUTH"

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
	; Use template engine to load the header of the page.  Convention is to use '<docroot>/start.html', which can include a <title>{%}title{%}</title> line in there
	; to make use of @AUTH@("logintitle")
	set localvar("title")=$get(@AUTH@("logintitle"))
	set response("lastmod")=$$loadcontent^template(docroot,docroot_"/start.html")

	; Set login form
	do addcontent^response("<h2>Login</h2><form action="""_urlroot_"login/"" method=""post""><p><label for=""username"">Username: </label><input type=""text"" name=""username"" /></p><p><label for=""password"">Password: </label><input type=""password"" name=""password"" /></p><p><input type=""submit"" value=""Login"" /></p></form>")

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
	new content,i

	for i=1:1:2 do
	.	set value=$zpiece(request("content"),"&",i)
	.	set content($zpiece(value,"=",1))=$zpiece(value,"=",2,$zlength(line))

	new localvar,lastmod,session
	; Use template engine to load the header of the page.  Convention is to use '<docroot>/start.html', which can include a <title>{%}title{%}</title> line in there
	; to make use of @AUTH@("logintitle")
	set localvar("title")=$get(@AUTH@("logintitle"))
	set response("lastmod")=$$loadcontent^template(docroot,docroot_"/start.html")

	if $data(@AUTH@("accounts",content("username"))) do  if 1
	.	if @AUTH@("accounts",content("username"),"password")=$$hash(content("password"),@AUTH@("accounts",content("username"),"salt")) do  if 1
	.	.	set session=$$encode^base64($$salt(16))
	.	.	do addcontent^response("Welcome back "_content("username")_"!")
	.	.	set response("headers","Set-Cookie")="session="_session_"; Path=/; HttpOnly; Secure"
	.	.	set @SESSION@(session)=content("username")
	.	else  do addcontent^response("Wrong username or password...") if 1
	else  do addcontent^response("Wrong username or password...") if 1

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
	; Use template engine to load the header of the page.  Convention is to use '<docroot>/start.html', which can include a <title>{%}title{%}</title> line in there
	; to make use of @AUTH@("logintitle")
	set localvar("title")=$get(@AUTH@("logintitle"))
	set response("lastmod")=$$loadcontent^template(docroot,docroot_"/start.html")

	do addcontent^response("<h2>Logged out!</h2>")
	set response("headers","Set-Cookie")="session=deleted; Path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT"
	kill @SESSION@($get(request("headers","COOKIE","session")," "))

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
	new salt,i
	set salt=""

	for i=1:1:count set salt=salt_$random(10)

	quit salt

username()
	;
	; Return the username for the session of the current request.  Empty string if not found or invalid.
	;
	quit $get(@SESSION@($get(request("headers","COOKIE","session")," ")))

isauthenticated()
	;
	; Return 1 if the request is from an authenticated user, 0 otherwise.
	;
	quit $data(@SESSION@($get(request("headers","COOKIE","session")," ")))

adduser(username,password,AUTH)
	;
	; Add a new user
	;
	new salt,saltedpass

	; Default AUTH
	if '$data(AUTH) new AUTH set AUTH="^AUTH"

	set salt=$$salt(64)
	set saltedpass=$$hash(password,salt)

	tstart ():serial
	set:'$data(@AUTH@("accounts",username)) @AUTH@("accounts",username,"password")=saltedpass,@AUTH@("accounts",username,"salt")=salt
	tcommit

	quit
