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

handle(docroot,urlroot,NEWS)
	;
	; Response handlers that implement a news/blog type of pages.
	; 
	; docroot represent a directory containing some templates used to generate the various pages.
	; urlroot represent the url root that is being handled.  Will be used to create appropriate links.  Default to '/'
	; NEWS represent the global to use to store the news data.
	;
	new localvar

	; Support GET and HEAD methods
	quit:'$$methodis^request("GET,HEAD,PUT,POST")
	
	; Default urlroot
	if '$data(urlroot) new urlroot set urlroot="/"
	; Default NEWS
	if '$data(NEWS) new NEWS set NEWS="^NEWS"

	; Allow templates to display differently if the user is authenticated (ie. auth=2) or if it isn't (auth=1)
	if $$isauthenticated^auth() do
	.	set localvar("auth")=2
	.	; No cache when logged in.
	.	set response("headers","Cache-Control")="no-cache"
	else  set localvar("auth")=1

	; Return an atom feed for a "/<urlroot>/atom.xml" request,
	; an archive/all posts HTML page for a "/<urlroot>/archive/" request,
	; a specific post HTML page for a "/<urlroot>/posts/<id>" request,
	; and a home HTML page with the latest 5 elements for a "/<urlroot>/" request.
	if request("uri")=(urlroot_"atom.xml") do atomfeed(urlroot)  if 1
	else  if request("uri")=urlroot do main(docroot,urlroot)  if 1
	else  if request("uri")=(urlroot_"archive/") do archive(docroot,urlroot)  if 1
	else  if request("uri")=(urlroot_"admin/") do admin(docroot,urlroot)  if 1
	else  if $zextract(request("uri"),1,$zlength(urlroot_"admin/"))=(urlroot_"admin/") do adminaction(docroot,urlroot)  if 1
	else  if $zextract(request("uri"),1,$zlength(urlroot_"posts/"))=(urlroot_"posts/") do post(docroot)  if 1
	; Everything else is 404 Not Found.
	else  do set^response(404) quit

	; Get md5sum of the generated content.
	do md5sum^response()

	; Validate the cache
	do validatecache^request()

	quit

atomfeed(urlroot)
	;
	; Handle feed request
	;
	new header,author,posts,footer,postid,tag

	; Header
	set header="<?xml version=""1.0"" encoding=""utf-8""?><feed xmlns=""http://www.w3.org/2005/Atom"">"
	set header=header_"<title>"_$get(@NEWS@("title"))_"</title>"_"<link href=""http://"_request("headers","HOST")_request("uri")_""" rel=""self"" type=""application/atom+xml"" />"
	set header=header_"<link href=""http://"_request("headers","HOST")_urlroot_""" />"_"<id>http://"_request("headers","HOST")_request("uri")_"</id>"
	
	; Auhor
	set author="<author>"
	set tag=$order(@NEWS@("author",""))
	for  quit:tag=""  do
	.	set author=author_"<"_tag_">"_@NEWS@("author",tag)_"</"_tag_">"
	.	set tag=$order(@NEWS@("author",tag))
	set author=author_"</author>"

	; Posts
	set postid=$order(@NEWS@("post",""))
	set posts=""
	set response("lastmod")="0,0"
	for  quit:postid=""  do
	.	set posts=posts_"<entry><title>"_@NEWS@("post",postid,"title")_"</title><link href=""http://"_request("headers","HOST")_urlroot_"posts/"_postid_""" />"
	.	set posts=posts_"<id>"_request("headers","HOST")_":"_postid_"</id>"
	.	set posts=posts_"<published>"_$zdate(@NEWS@("post",postid,"published"),"YEAR-MON-DD")_"T"_$zdate(@NEWS@("post",postid,"published"),"24:60:SS")_"Z</published>"
	.	set posts=posts_"<updated>"_$zdate(@NEWS@("post",postid,"updated"),"YEAR-MON-DD")_"T"_$zdate(@NEWS@("post",postid,"updated"),"24:60:SS")_"Z</updated>"
	.	set posts=posts_"<summary>"_$get(@NEWS@("post",postid,"summary"))_"</summary></entry>"
	.	; Update last modified date if needed.
	.	set:$$isnewer^date(@NEWS@("post",postid,"updated"),response("lastmod")) response("lastmod")=@NEWS@("post",postid,"updated")
	.	set response("glolist","@NEWS@(""post"","_postid_",""updated"")")=""
	.	; Get next post
	.	set postid=$order(@NEWS@("post",postid))

	set header=header_"<updated>"_$zdate(response("lastmod"),"YEAR-MON-DD")_"T"_$zdate(response("lastmod"),"24:60:SS")_"Z</updated>"

	; Footer
	set footer="</feed>"

	do addcontent^response(header_author_posts_footer)

	set response("headers","Content-Type")="application/atom+xml"

	quit

main(docroot,urlroot)
	;
	; Handle main page
	;
	new lastmod

	; Use template engine to load the header of the page.  Convention is to use '<docroot>/start.html', which can include a <title>{%}title{%}</title> line in there
	; to make use of @NEWS@("title"), and {%}auth{%} to insert login/logout/admin links
	set localvar("title")=$get(@NEWS@("title"))
	set response("lastmod")=$$loadcontent^template(docroot,docroot_"/start.html")

	; Populate content from database, up to 5 items, if any
	new postid,cnt
	set postid=$order(@NEWS@("post",""),-1)
	set cnt=0
	do addcontent^response("<h2>"_$get(@NEWS@("title"))_"</h2>")
	for  quit:postid=""  quit:cnt=5  do
	.	do addcontent^response("<h3>"_@NEWS@("post",postid,"title")_"</h3><h4>"_$zdate(@NEWS@("post",postid,"published"),"DAY, DD MON YEAR")_"</h4><p>"_@NEWS@("post",postid,"content")_"</p>")
	.	; Update last modified date if needed.
	.	set:$$isnewer^date(@NEWS@("post",postid,"updated"),response("lastmod")) response("lastmod")=@NEWS@("post",postid,"updated")
	.	set response("glolist","@NEWS@(""post"","_postid_",""updated"")")=""
	.	; Get next post
	.	set postid=$order(@NEWS@("post",postid),-1)
	.	set cnt=cnt+1

	; Add link to archives (all posts)
	do addcontent^response("<p>Browse <a href="""_urlroot_"archive/"">older posts</a>.</p>")

	; Use template engine to load the footer of the page.  Convention is to use '<docroot>/end.html'.
	set lastmod=$$loadcontent^template(docroot,docroot_"/end.html")
	; Update last modified date if needed.
	set:$$isnewer^date(lastmod,response("lastmod")) response("lastmod")=lastmod

	; Set response's content type
	set response("headers","Content-Type")="text/html"

	quit

archive(docroot,urlroot)
	;
	; Handle archive page
	;
	new lastmod

	; Use template engine to load the header of the page.  Convention is to use '<docroot>/start.html', which can include a <title>{%}title{%}</title> line in there
	; to make use of @NEWS@("title")
	set localvar("title")=$get(@NEWS@("title"))_" | Archive"
	set response("lastmod")=$$loadcontent^template(docroot,docroot_"/start.html")

	; List all posts from database
	new postid,cnt
	set postid=$order(@NEWS@("post",""),-1)
	set cnt=0
	do addcontent^response("<h2>"_$get(@NEWS@("title"))_"</h2><h3>Archive</h3>")
	for  quit:postid=""  do
	.	do addcontent^response("<a href="""_urlroot_"posts/"_postid_""">"_@NEWS@("post",postid,"title")_"</a><br>")
	.	; Update last modified date if needed.
	.	set:$$isnewer^date(@NEWS@("post",postid,"updated"),response("lastmod")) response("lastmod")=@NEWS@("post",postid,"updated")
	.	set response("glolist","@NEWS@(""post"","_postid_",""updated"")")=""
	.	; Get next post
	.	set postid=$order(@NEWS@("post",postid),-1)

	; Use template engine to load the footer of the page.  Convention is to use '<docroot>/end.html'.
	set lastmod=$$loadcontent^template(docroot,docroot_"/end.html")
	; Update last modified date if needed.
	set:$$isnewer^date(lastmod,response("lastmod")) response("lastmod")=lastmod

	; Set response's content type
	set response("headers","Content-Type")="text/html"

	quit

post(docroot)
	;
	; Handle specific post
	;
	new lastmod,postid

	set postid=$zpiece(request("uri"),"/",4,4)
	if '$data(@NEWS@("post",postid)) do set^response(405) quit
	; Use template engine to load the header of the page.  Convention is to use '<docroot>/start.html', which can include a <title>{%}title{%}</title> line in there
	; to make use of @NEWS@("title")
	set localvar("title")=$get(@NEWS@("title"))_" | "_@NEWS@("post",postid,"title")
	set response("lastmod")=$$loadcontent^template(docroot,docroot_"/start.html")

	; A post from database
	do addcontent^response("<h2>"_$get(@NEWS@("title"))_"</h2><h3>"_@NEWS@("post",postid,"title")_"</h3><h4>"_$zdate(@NEWS@("post",postid,"published"),"DAY, DD MON YEAR")_"</h4><p>"_@NEWS@("post",postid,"content")_"</p>")
	; Update last modified date if needed.
	set:$$isnewer^date(@NEWS@("post",postid,"updated"),response("lastmod")) response("lastmod")=@NEWS@("post",postid,"updated")
	set response("glolist","@NEWS@(""post"","_postid_",""updated"")")=""

	; Use template engine to load the footer of the page.  Convention is to use '<docroot>/end.html'.
	set lastmod=$$loadcontent^template(docroot,docroot_"/end.html")
	; Update last modified date if needed.
	set:$$isnewer^date(lastmod,response("lastmod")) response("lastmod")=lastmod

	; Set response's content type
	set response("headers","Content-Type")="text/html"

	quit

admin(docroot,urlroot)
	;
	; Handle admin page
	;
	new lastmod

	; This page is only accessible to logged in user
	if '$$isauthenticated^auth() do set^response(403) quit

	; Use template engine to load the header of the page.  Convention is to use '<docroot>/start.html', which can include a <title>{%}title{%}</title> line in there
	; to make use of @NEWS@("title")
	set localvar("title")=$get(@NEWS@("title"))_" | Admin"
	set response("lastmod")=$$loadcontent^template(docroot,docroot_"/start.html")

	; Link to create a new post
	do addcontent^response("<h2>"_$get(@NEWS@("title"))_"</h2><p>Create a <a href="""_urlroot_"admin/add/"">New Post</a></p>")

	; Form to edit Title and Authors
	do addcontent^response("<form enctype=""application/x-www-form-urlencoded"" accept-charset=""UTF-8"" action="""_urlroot_"admin/update/"" method=""post""><p><label for=""title"">Title: </label><input type=""text"" name=""title"" /></p><p><label for=""author"">Author: </label><input type=""text"" name=""author"" /></p><p><label for=""email"">Email: </label><input type=""text"" name=""email"" /></p><p><label for=""uri"">URI: </label><input type=""text"" name=""uri"" /></p><p><input type=""submit"" value=""Update"" /></p></form>")

	; List all posts from database
	new postid,cnt
	set postid=$order(@NEWS@("post",""),-1)
	set cnt=0
	do addcontent^response("<h3>All Posts</h3>")
	for  quit:postid=""  do
	.	do addcontent^response("<a href="""_urlroot_"posts/"_postid_""">"_@NEWS@("post",postid,"title")_"</a> <a href="""_urlroot_"admin/delete/"_postid_""">Delete</a> <a href="""_urlroot_"admin/edit/"_postid_""">Edit</a><br>")
	.	; Update last modified date if needed.
	.	set:$$isnewer^date(@NEWS@("post",postid,"updated"),response("lastmod")) response("lastmod")=@NEWS@("post",postid,"updated")
	.	set response("glolist","@NEWS@(""post"","_postid_",""updated"")")=""
	.	; Get next post
	.	set postid=$order(@NEWS@("post",postid),-1)

	; Use template engine to load the footer of the page.  Convention is to use '<docroot>/end.html'.
	set lastmod=$$loadcontent^template(docroot,docroot_"/end.html")
	; Update last modified date if needed.
	set:$$isnewer^date(lastmod,response("lastmod")) response("lastmod")=lastmod

	; Set response's content type
	set response("headers","Content-Type")="text/html"

	quit

adminaction(docroot,urlroot)
	;
	; Handle various admin actions
	;
	new lastmod,action,postid,content,value,i

	; This page is only accessible to logged in user
	if '$$isauthenticated^auth() do set^response(404) quit

	set action=$zpiece(request("uri"),"/",4,4)
	set postid=$zpiece(request("uri"),"/",5,5)

	; Use template engine to load the header of the page.  Convention is to use '<docroot>/start.html', which can include a <title>{%}title{%}</title> line in there
	; to make use of @NEWS@("title")
	set localvar("title")=$get(@NEWS@("title"))_" | Admin"
	set response("lastmod")=$$loadcontent^template(docroot,docroot_"/start.html")

	;
	if action="add" do
	.	if $$methodis^request("PUT,POST") do  if 1
	.	.	do addcontent^response("<h2>Post published!</h2>")
	.	.	for i=1:1:3 set value=$zpiece(request("content"),"&",i),content($zpiece(value,"=",1))=$$paragraph($$decode^url($zpiece(value,"=",2,$zlength(line))))
	.	.	tstart ():serial
	.	.	set:postid="" (postid,@NEWS@("count"))=$get(@NEWS@("count"))+1
	.	.	set @NEWS@("post",postid,"title")=$get(content("title"))
	.	.	set @NEWS@("post",postid,"summary")=$get(content("summary"))
	.	.	set @NEWS@("post",postid,"content")=$get(content("content"))
	.	.	set @NEWS@("post",postid,"updated")=$horolog
	.	.	set:$get(@NEWS@("post",postid,"published"))="" @NEWS@("post",postid,"published")=@NEWS@("post",postid,"updated")
	.	.	tcommit
	.	else  do
	.	.	do addcontent^response("<h2>New post</h2><form enctype=""application/x-www-form-urlencoded"" accept-charset=""UTF-8"" action="""_urlroot_"admin/add/"" method=""post""><p><label for=""title"">Title: </label><input type=""text"" name=""title"" /></p><p><label for=""summary"">Summary: </label><input type=""text"" name=""summary"" /></p><p><label for=""content"">Content: </label><textarea wrap=""virtual"" name=""content"" rows=""10"" cols=""35""></textarea></p><p><input type=""submit"" value=""Publish"" /></p></form>") if 1
	else  if action="delete" kill @NEWS@("post",postid) do addcontent^response("<h2>Post deleted</h2>") if 1
	else  if action="edit" do addcontent^response("<h2>New post</h2><form enctype=""application/x-www-form-urlencoded"" accept-charset=""UTF-8"" action="""_urlroot_"admin/add/"_postid_""" method=""post""><p><label for=""title"">Title: </label><input type=""text"" name=""title"" value="""_@NEWS@("post",postid,"title")_"""/></p><p><label for=""summary"">Summary: </label><input type=""text"" name=""summary"" value="""_@NEWS@("post",postid,"summary")_"""/></p><p><label for=""content"">Content: </label><textarea wrap=""virtual"" name=""content"" rows=""10"" cols=""35"">"_@NEWS@("post",postid,"content")_"</textarea></p><p><input type=""submit"" value=""Publish"" /></p></form>") if 1
	else  if action="update" do
	.	if $$methodis^request("PUT,POST") do  if 1
	.	.	do addcontent^response("<h2>Updated!</h2>")
	.	.	for i=1:1:4 set value=$zpiece(request("content"),"&",i),content($zpiece(value,"=",1))=$$paragraph($$decode^url($zpiece(value,"=",2,$zlength(line))))
	.	.	tstart ():serial
	.	.	set @NEWS@("title")=$get(content("title"))
	.	.	set @NEWS@("author","name")=$get(content("author"))
	.	.	set @NEWS@("author","email")=$get(content("email"))
	.	.	set @NEWS@("author","uri")=$get(content("uri"))
	.	.	tcommit
	.	else  kill response("content"),response("lastmod") do set^response(404) quit
	else  kill response("content"),response("lastmod") do set^response(404) quit

	; Use template engine to load the footer of the page.  Convention is to use '<docroot>/end.html'.
	set lastmod=$$loadcontent^template(docroot,docroot_"/end.html")
	; Update last modified date if needed.
	set:$$isnewer^date(lastmod,response("lastmod")) response("lastmod")=lastmod

	; Set response's content type
	set response("headers","Content-Type")="text/html"

	quit

paragraph(text)
	;
	; Convert inline CRLF into a </p><p> structured text.
	;
	new p,br
	set br=$char(13)_$char(10)
	set p=text
	for  quit:$zfind(p,br)=0  do
	.	set p=$zpiece(p,br,1)_"</p><p>"_$zpiece(p,br,2,$zlength(p))
	quit p
