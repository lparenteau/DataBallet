;
;  GT.M Base64 Extension
;  Copyright (C) 2012 Laurent Parenteau <laurent.parenteau@gmail.com>
;
;  This program is free software: you can redistribute it and/or modify
;  it under the terms of the GNU Affero General Public License as
;  published by the Free Software Foundation, either version 3 of the
;  License, or (at your option) any later version.
;
;  This program is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;  GNU Affero General Public License for more details.
;
;  You should have received a copy of the GNU Affero General Public License
;  along with this program.  If not, see <http://www.gnu.org/licenses/>.
;

; GT.M Base64 Extension
;
; This allow Base64 encoding using OpenSSL.
;

encode(message)
	;
	; Return base64 encoded message.
	new base64
	do &base64.encode(4,5,.message,.base64)
	quit base64
