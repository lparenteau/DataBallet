	;
	; This file is part of DataBallet.
	; Copyright (C) 2012-2013 Laurent Parenteau <laurent.parenteau@gmail.com>
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
	quit:'$$methodis^request("GET,HEAD,PUT,POST",1)
	
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

	; Load title
	set localvar("title")=$get(@NEWS@("title"))

	; Ensure it won't be served from cache if new post or title/author changed.
	set response("glolist",NEWS_"(""updated"")")=""

	; Return an atom feed for a "/<urlroot>/atom.xml" request,
	; an archive/all posts HTML page for a "/<urlroot>/archive/" request,
	; a specific post HTML page for a "/<urlroot>/posts/<id>" request,
	; and a home HTML page with the latest 5 elements for a "/<urlroot>/" request.
	if request("uri")=(urlroot_"atom.xml") do atomfeed(urlroot)  if 1
	else  if request("uri")=urlroot do archive(docroot,urlroot,5)  if 1
	else  if request("uri")=(urlroot_"archive/") do archive(docroot,urlroot)  if 1
	else  if request("uri")=(urlroot_"admin/") do admin(docroot,urlroot)  if 1
	else  if $zextract(request("uri"),1,$zlength(urlroot_"admin/"))=(urlroot_"admin/") do adminaction(docroot,urlroot)  if 1
	else  if $zextract(request("uri"),1,$zlength(urlroot_"posts/"))=(urlroot_"posts/") do post(docroot,urlroot)  if 1
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
	new header,author,posts,footer,postid,tag,host

	set host=$$FUNC^%LCASE(request("headers","HOST"))

	; Header
	set header="<?xml version=""1.0"" encoding=""utf-8""?><feed xmlns=""http://www.w3.org/2005/Atom"">"_eol
	set header=header_"<title>"_$get(@NEWS@("title"))_"</title>"_"<link href=""http://"_host_request("uri")_""" rel=""self"" type=""application/atom+xml"" />"_eol
	set header=header_"<link href=""http://"_request("headers","HOST")_urlroot_""" />"_"<id>http://"_host_request("uri")_"</id>"_eol
	
	; Auhor
	set author="<author>"
	set tag=$order(@NEWS@("author",""))
	for  quit:tag=""  do
	.	set author=author_"<"_tag_">"_@NEWS@("author",tag)_"</"_tag_">"
	.	set tag=$order(@NEWS@("author",tag))
	set author=author_"</author>"

	; Posts
	set postid=$order(@NEWS@("post",""),-1)
	set posts=""
	set response("lastmod")="0,0"
	for  quit:postid=""  do
	.	set posts=posts_"<entry><title>"_@NEWS@("post",postid,"title")_"</title><link href=""http://"_request("headers","HOST")_urlroot_"posts/"_postid_""" />"_eol
	.	set posts=posts_"<id>"_host_":"_postid_"</id>"_eol
	.	set posts=posts_"<published>"_$zdate(@NEWS@("post",postid,"published"),"YEAR-MM-DD")_"T"_$zdate(@NEWS@("post",postid,"published"),"24:60:SS")_"Z</published>"_eol
	.	set posts=posts_"<updated>"_$zdate(@NEWS@("post",postid,"updated"),"YEAR-MM-DD")_"T"_$zdate(@NEWS@("post",postid,"updated"),"24:60:SS")_"Z</updated>"_eol
	.	set posts=posts_"<summary>"_$get(@NEWS@("post",postid,"summary"))_"</summary></entry>"_eol
	.	; Update last modified date if needed.
	.	set:$$isnewer^date(@NEWS@("post",postid,"updated"),response("lastmod")) response("lastmod")=@NEWS@("post",postid,"updated")
	.	set response("glolist",NEWS_"(""post"","_postid_",""updated"")")=""
	.	; Get next post
	.	set postid=$order(@NEWS@("post",postid),-1)

	set header=header_"<updated>"_$zdate(response("lastmod"),"YEAR-MM-DD")_"T"_$zdate(response("lastmod"),"24:60:SS")_"Z</updated>"

	; Footer
	set footer="</feed>"

	do addcontent^response(header_author_posts_footer)

	set response("headers","Content-Type")="application/atom+xml"

	quit

archive(docroot,urlroot,max)
	;
	; Handle main page (with a maximum number of entries displayed) or a full archive page (with no maximum number of entries).
	;
	; We use the templating engine to build the page, so we only have to populate localvar(...) with what we want, then load the template.
	; The template loaded is '<docroot>/news.html'.
	;
	new lastmod

	; Request action is 'main' for the / page (with a max) or 'archive' for '/archive/'
	set localvar("action")=$select($data(max):"main",1:"archive")

	; Load content from database, up to max items, if any
	new postid,cnt
	set postid=$order(@NEWS@("post",""),-1)
	set cnt=0
	set response("lastmod")=0
	for  quit:postid=""  quit:cnt=$get(max,-1)  do
	.	set localvar("post",cnt,"title")=@NEWS@("post",postid,"title")
	.	set localvar("post",cnt,"date")=$zdate(@NEWS@("post",postid,"published"),"DAY, DD MON YEAR")
	.	set localvar("post",cnt,"content")=@NEWS@("post",postid,"content")
	.	set localvar("post",cnt,"id")=postid
	.	; Update last modified date if needed.
	.	set:$$isnewer^date(@NEWS@("post",postid,"updated"),response("lastmod")) response("lastmod")=@NEWS@("post",postid,"updated")
	.	set response("glolist",NEWS_"(""post"","_postid_",""updated"")")=""
	.	; Get next post
	.	set postid=$order(@NEWS@("post",postid),-1)
	.	set cnt=cnt+1

	; Use the template engine to populate the response.
	set lastmod=$$loadcontent^template(docroot,docroot_"/news.html")

	; Update last modified date if needed.
	set:$$isnewer^date(lastmod,response("lastmod")) response("lastmod")=lastmod

	; Set response's content type
	set response("headers","Content-Type")="text/html"

	quit

post(docroot,urlroot)
	;
	; Handle specific post
	;
	; We use the templating engine to build the page, so we only have to populate localvar(...) with what we want, then load the template.
	; The template loaded is '<docroot>/news.html'.
	;
	new lastmod,postid

	set postid=$zpiece($zpiece(request("uri"),"/",4,4),"?",1,1)
	; Redirect to archive if no post requested
	if postid="" do set^response(301)  set response("headers","Location")=urlroot_"archive/" quit

	; 404 if requested post does not exist
	if '$data(@NEWS@("post",postid)) do set^response(404) quit

	; Request action is 'post'
	set localvar("action")="post"

	; Load the post from database
	set localvar("post_title")=@NEWS@("post",postid,"title")
	set localvar("post_date")=$zdate(@NEWS@("post",postid,"published"),"DAY, DD MON YEAR")
	set localvar("post_content")=@NEWS@("post",postid,"content")
	set localvar("post_id")=postid

	; Set last modified date.
	set response("lastmod")=@NEWS@("post",postid,"updated")
	set response("glolist",NEWS_"(""post"","_postid_",""updated"")")=""

	; Use the template engine to populate the response.
	set lastmod=$$loadcontent^template(docroot,docroot_"/news.html")

	; Update last modified date if needed.
	set:$$isnewer^date(lastmod,response("lastmod")) response("lastmod")=lastmod

	; Set response's content type
	set response("headers","Content-Type")="text/html"

	quit

admin(docroot,urlroot)
	;
	; Handle admin page
	;
	; We use the templating engine to build the page, so we only have to populate localvar(...) with what we want, then load the template.
	; The template loaded is '<docroot>/news.html'.
	;
	new lastmod

	; This page is only accessible to logged in user
	if '$$isauthenticated^auth() do set^response(403) quit

	; Request action is 'admin'
	set localvar("action")="admin"

	; Load current author
	set localvar("author")=$get(@NEWS@("author","name"))
	set localvar("author_email")=$get(@NEWS@("author","email"))
	set localvar("author_uri")=$get(@NEWS@("author","uri"))

	; Load all posts title and date from database if any
	new postid,cnt
	set postid=$order(@NEWS@("post",""),-1)
	set cnt=0
	set response("lastmod")=0
	for  quit:postid=""  do
	.	set localvar("post",cnt,"title")=@NEWS@("post",postid,"title")
	.	set localvar("post",cnt,"date")=$zdate(@NEWS@("post",postid,"published"),"DAY, DD MON YEAR")
	.	set localvar("post",cnt,"id")=postid
	.	; Update last modified date if needed.
	.	set:$$isnewer^date(@NEWS@("post",postid,"updated"),response("lastmod")) response("lastmod")=@NEWS@("post",postid,"updated")
	.	set response("glolist",NEWS_"(""post"","_postid_",""updated"")")=""
	.	; Get next post
	.	set postid=$order(@NEWS@("post",postid),-1)
	.	set cnt=cnt+1

	; Use the template engine to populate the response.
	set lastmod=$$loadcontent^template(docroot,docroot_"/news.html")

	; Update last modified date if needed.
	set:$$isnewer^date(lastmod,response("lastmod")) response("lastmod")=lastmod

	; Set response's content type
	set response("headers","Content-Type")="text/html"

	quit

adminaction(docroot,urlroot)
	;
	; Handle various admin actions
	;
	; We use the templating engine to build the page, so we only have to populate localvar(...) with what we want, then load the template.
	; The template loaded is '<docroot>/news.html'.
	;
	new lastmod,action,postid,content,value,i

	; This page is only accessible to logged in user
	if '$$isauthenticated^auth() do set^response(404) quit

	set action=$zpiece(request("uri"),"/",4,4)
	set postid=$zpiece(request("uri"),"/",5,5)

	;
	if action="delete" kill @NEWS@("post",postid) do set^response(303)  set response("headers","Location")=urlroot_"admin/"  if 1
	else  if action="edit" do  if 1
	.	set localvar("action")="edit"
	.	if postid'="" do
	.	.	set localvar("post_title")=$get(@NEWS@("post",postid,"title"),"")
	.	.	set localvar("post_date")=$zdate($get(@NEWS@("post",postid,"published"),""),"DAY, DD MON YEAR")
	.	.	set localvar("post_content")=$get(@NEWS@("post",postid,"content"),"")
	.	.	set localvar("post_summary")=$get(@NEWS@("post",postid,"summary"),"")
	.	.	set localvar("post_id")=postid
	.	; Use the template engine to populate the response.
	.	set response("lastmod")=$$loadcontent^template(docroot,docroot_"/news.html")
	.	; Set response's content type
	.	set response("headers","Content-Type")="text/html"
	else  if action="add" do  if 1
	.	if $$methodis^request("PUT,POST") do  if 1
	.	.	for i=1:1:3 set value=$zpiece(request("content"),"&",i),content($zpiece(value,"=",1))=$$paragraph($$decode^url($zpiece(value,"=",2,$zlength(line))))
	.	.	if postid'="" do update^news(postid,$get(content("title")),$get(content("summary")),$get(content("content")))  if 1
	.	.	else  do publish^news($get(content("title")),$get(content("summary")),$get(content("content")))
	.	.	do set^response(303)  set response("headers","Location")=urlroot_"admin/"
	.	else  do set^response(404)
	else  if action="update" do  if 1
	.	if $$methodis^request("PUT,POST") do  if 1
	.	.	for i=1:1:4 set value=$zpiece(request("content"),"&",i),content($zpiece(value,"=",1))=$$paragraph($$decode^url($zpiece(value,"=",2,$zlength(line))))
	.	.	tstart ():serial
	.	.	set @NEWS@("title")=$get(content("title"))
	.	.	set @NEWS@("author","name")=$get(content("author"))
	.	.	set @NEWS@("author","email")=$get(content("email"))
	.	.	set @NEWS@("author","uri")=$get(content("uri"))
	.	.	set @NEWS@("updated")=$horolog
	.	.	tcommit
	.	.	do set^response(303)  set response("headers","Location")=urlroot_"admin/"
	.	else  do set^response(404)
	else  do set^response(404)

	quit

paragraph(text)
	;
	; Convert inline CRLF into a </p><p> structured text.
	;
	new p,br
	set br=$char(13)_$char(10)
	set p=text
	for  quit:$zfind(p,br)=0  do
	.	new start
	.	set start=$zpiece(p,br,1)
	.	; Only add '</p><p>' if the last piece of the string isn't that already.  This prevent
	.	; multiple consecutives CRLF to be translated into multiple empty paragraphs.
	.	if $zextract(start,$zlength(start)-6,$zlength(start))'="</p><p>"  do
	.	.	set p=start_"</p><p>"_$zpiece(p,br,2,$zlength(p))
	quit p

publish(title,summary,content,published)
	;
	; Publish a NEWS entry.
	;
	; All parameters are optional and default to an empty string, expect for published which default to $horolog.
	;
	new postid,now

	; Default NEWS
	if '$data(NEWS) new NEWS set NEWS="^NEWS"

	set now=$HOROLOG
	tstart ():serial
	set (postid,@NEWS@("count"))=$get(@NEWS@("count"))+1
	set @NEWS@("updated")=now
	set @NEWS@("post",postid,"title")=$get(title)
	set @NEWS@("post",postid,"summary")=$get(summary)
	set @NEWS@("post",postid,"content")=$get(content)
	set @NEWS@("post",postid,"updated")=$get(published,now)
	set:$get(@NEWS@("post",postid,"published"))="" @NEWS@("post",postid,"published")=@NEWS@("post",postid,"updated")
	tcommit

	quit

update(postid,title,summary,content)
	;
	; Update a NEWS entry.
	;
	; All parameters excepting postid are optional and default to the current value.
	;

	; Default NEWS
	if '$data(NEWS) new NEWS set NEWS="^NEWS"

	tstart ():serial
	set:$data(title) @NEWS@("post",postid,"title")=title
	set:$data(summary) @NEWS@("post",postid,"summary")=summary
	set:$data(content) @NEWS@("post",postid,"content")=content
	set @NEWS@("post",postid,"updated")=$horolog
	tcommit

	quit

