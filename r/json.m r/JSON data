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

decode(json,var,nextisname,inarray)
	;
	; Populate the local variable 'var' based on the json string received.
	; Return 0 on success, 1 otherwise
	;
	new status,first,subscript,length,base,end

	; Quit on empty string
	quit:json="" 1

	set status=0
	set end=0
	set length=$zlength(json)
	if $zextract(var,$zlength(var))=")" set base=$zextract(var,1,$zlength(var)-1)_","
	else  set base=var_"("
	for  quit:json=""  quit:status'=0  quit:end=1  do
	.	set first=$zextract(json,1,1)
	.	if first="{" do  if 1
	.	.	set:$get(inarray,0)=1 var=base_"0)" ; First item of array, add a '0' subscript
	.	.	set json=$zextract(json,2,length) ; skip over {
	.	.	set status=$$decode^json(.json,var,1)
	.	else  if first="," do  if 1
	.	.	set json=$zextract(json,2,length) ; skip over ,
	.	.	if $get(inarray,0)>0 do
	.	.	.	set subscript=inarray
	.	.	.	set inarray=inarray+1
	.	.	else  do
	.	.	.	set subscript=$zpiece(json,"""",2)
	.	.	.	set json=$zpiece(json,"""",3,length) ; skip over ..."
	.	.	set var=base_""""_subscript_""")"
	.	else  if first=":" do  if 1
	.	.	set json=$zextract(json,2,length) ; skip over :
	.	else  if first="[" do  if 1
	.	.	set json=$zextract(json,2,length) ; skip over [
	.	.	set status=$$decode^json(.json,var,0,1)
	.	else  if first="""" do  if 1
	.	.	new value,piece
	.	.	set:$get(inarray,0)=1 var=base_"0)" ; First item of array, add a '0' subscript
	.	.	set piece=2
	.	.	set value=$zpiece(json,"""",piece)
	.	.	for  quit:$zextract(value,$zlength(value))'="\"  do ; Handle espaced '"'
	.	.	.	set piece=piece+1
	.	.	.	set value=$zextract(value,1,$zlength(value)-1)_""""_$zpiece(json,"""",piece)
	.	.	if $get(nextisname,0)=1 set var=base_""""_value_""")" set nextisname=0
	.	.	else  set @var=value
	.	.	set json=$zpiece(json,"""",piece+1,length) ; skip over ..."
	.	else  if first="}" do  if 1
	.	.	set json=$zextract(json,2,length) ; skip over }
	.	.	set end=1
	.	else  if first="]" do  if 1
	.	.	set json=$zextract(json,2,length) ; skip over ]
	.	.	set end=1
	.	else  if $$FUNC^%UCASE($zextract(json,1,5))="FALSE" do  if 1
	.	.	set:$get(inarray,0)=1 var=base_"0)" ; First item of array, add a '0' subscript
	.	.	set @var=0
	.	.	set json=$zextract(json,6,length) ; skip over false
	.	else  if $$FUNC^%UCASE($zextract(json,1,4))="TRUE" do  if 1
	.	.	set:$get(inarray,0)=1 var=base_"0)" ; First item of array, add a '0' subscript
	.	.	set @var=1
	.	.	set json=$zextract(json,5,length) ; skip over true
	.	else  do ; consider its a number
	.	.	set:$get(inarray,0)=1 var=base_"0)" ; First item of array, add a '0' subscript
	.	.	set @var=$get(@var,"")_$zextract(json,1)
	.	.	set json=$zextract(json,2,length) ; skip over the 1st digit
	set var=base

	quit status

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
