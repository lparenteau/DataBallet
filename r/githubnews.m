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

handle(NEWS)
	;
	; Response handlers to allow GitHub repository to post NEWS.  It is recommended to use a long random
	; URL when setting up a route for this handler, to prevent anyone from pushing junk in your NEWS.
	; Then, to automatically have a new post in your NEWS when something is pushed to your GitHub
	; repository, you use that URL to setup a webhook, as described here : https://help.github.com/articles/post-receive-hook
	; 
	new payload,push,status,postid,i

	; Support POST method only
	quit:'$$methodis^request("POST",1)
	
	; Default NEWS
	if '$data(NEWS) new NEWS set NEWS="^NEWS"

	set payload=$zpiece(request("content"),"=",2)
	set status=$$decode^json($$decode^url(payload),"push")
	if status=0 do  if 1
	.	for i=0:1:$order(push("commits",""),-1) do publish^news("Code committed to GitHub!",push("commits",i,"message"),"Commit <a href="""_push("commits",i,"url")_""">#"_push("commits",i,"id")_"</a>: "_push("commits",i,"message"))
	.	do addcontent^response("Thanks! :)")
	else  do addcontent^response("Sorry... :(")

	; Set content-type, plain text here as nobody really care for the response anyway, I think...
	set response("headers","Content-Type")="text/plain"

	; No cache for this.
	set response("headers","Cache-Control")="no-cache"

	; Get md5sum of the generated content.
	do md5sum^response()

	; Validate the cache
	do validatecache^request()

	quit
