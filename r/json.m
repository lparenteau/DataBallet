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

encode(glo)
	;
	; Return a JSON representation for the supplied global
	;
	new json,subscript,base,comma
	set json=""

	; Return empty string if global don't exist.
	quit:$data(@glo)=0 ""

	set json=json_"{"
	set:$data(@glo)'=10 json=json_""""":"""_$$escape(@glo)_"""",comma=1
	if $zfind(glo,")")=0 set base=glo_"("
	else   set base=$zextract(glo,1,$zlength(glo)-1)_","
	set glo=base_""""")"
	set subscript=$order(@glo)
	for  quit:subscript=""  do
	.	set:$data(comma) json=json_","
	.	set json=json_""""_subscript_""":"
	.	set glo=base_""""_subscript_""")"
	.	if $data(@glo)=1 set json=json_""""_$$escape(@glo)_""""
	.	else  set json=json_$$encode(glo)
	.	set subscript=$order(@glo)
	.	set comma=1
	set json=json_"}"

	quit json

escape(txt)
	;
	; Return an escaped JSON string
	;
	new escaped,i,a
	set escaped=""
	for i=1:1:$zlength(txt) do
	.	set a=$zascii(txt,i)
	.	if ((a>31)&(a'=34)&(a'=92)) set escaped=escaped_$zchar(a)
	.	else  set escaped=escaped_"\u00"_$$FUNC^%DH(a,2)

	quit escaped
