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

isolder(a,b)
	;
	; Compare two dates in $HOROLOG format, returning 1 if a is older than b, 0 otherwise.
	;
	new ha,hb,sa,sb
	set ha=$zpiece(a,",",1)
	set hb=$zpiece(b,",",1)
	set sa=$zpiece(a,",",2)
	set sb=$zpiece(b,",",2)

	quit $select((ha<hb)!((ha=hb)&(sa<sb)):1,1:0)

isnewer(a,b)
	;
	; Compare two dates in $HOROLOG format, returning 1 if a is newer than b, 0 otherwise.
	;
	new ha,hb,sa,sb
	set ha=$zpiece(a,",",1)
	set hb=$zpiece(b,",",1)
	set sa=$zpiece(a,",",2)
	set sb=$zpiece(b,",",2)

	quit $select((ha>hb)!((ha=hb)&(sa>sb)):1,1:0)
