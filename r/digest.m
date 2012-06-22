	;
	; This file is part of DataBallet.
	; Copyright (C) 2012 Laurent Parenteau <laurent.parenteau@gmail.com>
	;
	; DataBallet is free software: you can redistribute it and/or modify
	; it under the terms of the GNU Affero General Public License as
	; published by the Free Software Foundation, either version 3 of the
	; License, or (at your option) any later version.
	;
	; DataBallet is distributed in the hope that it will be useful,
	; but WITHOUT ANY WARRANTY; without even the implied warranty of
	; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	; GNU Affero General Public License for more details.
	;
	; You should have received a copy of the GNU Affero General Public License
	; along with DataBallet.  If not, see <http://www.gnu.org/licenses/>.
	;
	; Boolean functions based on "MD5 Implementation in M", Copyright (C) 2012 Piotr Koper <piotr.koper@gmail.com>, https://github.com/pkoper/juicy-m/blob/master/md5.m
	;

sha256(message)
	;
	; Return SHA-256 hash value for the given message.
	; Algorithm taken from https://en.wikipedia.org/wiki/SHA-2#Examples_of_SHA-2_variants.
	;
	new h,k,chunk,end,words,i,s0,s1,th

	; First 32 bits of the fractional parts of the square roots of the first 8 primes 2..19
	set h(0)=1779033703,h(1)=3144134277,h(2)=1013904242,h(3)=2773480762,h(4)=1359893119,h(5)=2600822924,h(6)=528734635,h(7)=1541459225
	; First 32 bits of the fractional parts of the cube roots of the first 64 primes 2..311
	set k(0)=1116352408,k(1)=1899447441,k(2)=3049323471,k(3)=3921009573,k(4)=961987163,k(5)=1508970993,k(6)=2453635748,k(7)=2870763221
	set k(8)=3624381080,k(9)=310598401,k(10)=607225278,k(11)=1426881987,k(12)=1925078388,k(13)=2162078206,k(14)=2614888103,k(15)=3248222580
	set k(16)=3835390401,k(17)=4022224774,k(18)=264347078,k(19)=604807628,k(20)=770255983,k(21)=1249150122,k(22)=1555081692,k(23)=1996064986
	set k(24)=2554220882,k(25)=2821834349,k(26)=2952996808,k(27)=3210313671,k(28)=3336571891,k(29)=3584528711,k(30)=113926993,k(31)=338241895
	set k(32)=666307205,k(33)=773529912,k(34)=1294757372,k(35)=1396182291,k(36)=1695183700,k(37)=1986661051,k(38)=2177026350,k(39)=2456956037
	set k(40)=2730485921,k(41)=2820302411,k(42)=3259730800,k(43)=3345764771,k(44)=3516065817,k(45)=3600352804,k(46)=4094571909,k(47)=275423344
	set k(48)=430227734,k(49)=506948616,k(50)=659060556,k(51)=883997877,k(52)=958139571,k(53)=1322822218,k(54)=1537002063,k(55)=1747873779
	set k(56)=1955562222,k(57)=2024104815,k(58)=2227730452,k(59)=2361852424,k(60)=2428436474,k(61)=2756734187,k(62)=3204031479,k(63)=3329325298

	set message=$$preprocess(message)

	set chunk=1,end=0
	for  quit:end  do
	.	for i=0:1:15 set words(i)=$$read4bytes(message,chunk),chunk=chunk+4
	.	if words(0)<0 set end=1 quit
	.	for i=16:1:63 do
	.	.	set s0=$$xor($$xor($$rightrotate(words(i-15),7),$$rightrotate(words(i-15),18)),$$rightshift(words(i-15),3))
	.	.	set s1=$$xor($$xor($$rightrotate(words(i-2),17),$$rightrotate(words(i-2),19)),$$rightshift(words(i-2),10))
	.	.	set words(i)=(((words(i-16)+s0)#4294967296+words(i-7))#4294967296+s1)#4294967296
	.	merge th=h
	.	for i=0:1:63 do
	.	.	set s0=($$xor($$xor($$rightrotate(th(0),2),$$rightrotate(th(0),13)),$$rightrotate(th(0),22))+$$xor($$xor($$and(th(0),th(1)),$$and(th(0),th(2))),$$and(th(1),th(2))))#4294967296
	.	.	set s1=((((($$xor($$xor($$rightrotate(th(4),6),$$rightrotate(th(4),11)),$$rightrotate(th(4),25))+$$xor($$and(th(4),th(5)),$$and($$not(th(4)),th(6))))#4294967296+th(7))#4294967296+k(i))#4294967296)+words(i))#4294967296
	.	.	set th(7)=th(6)
	.	.	set th(6)=th(5)
	.	.	set th(5)=th(4)
	.	.	set th(4)=(th(3)+s1)#4294967296
	.	.	set th(3)=th(2)
	.	.	set th(2)=th(1)
	.	.	set th(1)=th(0)
	.	.	set th(0)=(s0+s1)#4294967296
	.	set h(0)=(h(0)+th(0))#4294967296
	.	set h(1)=(h(1)+th(1))#4294967296
	.	set h(2)=(h(2)+th(2))#4294967296
	.	set h(3)=(h(3)+th(3))#4294967296
	.	set h(4)=(h(4)+th(4))#4294967296
	.	set h(5)=(h(5)+th(5))#4294967296
	.	set h(6)=(h(6)+th(6))#4294967296
	.	set h(7)=(h(7)+th(7))#4294967296
	quit $$FUNC^%DH(h(0))_$$FUNC^%DH(h(1))_$$FUNC^%DH(h(2))_$$FUNC^%DH(h(3))_$$FUNC^%DH(h(4))_$$FUNC^%DH(h(5))_$$FUNC^%DH(h(6))_$$FUNC^%DH(h(7))

preprocess(message)
	;
	; Preprocessing routine.
	;
	new m
	set $zpiece(m,$zchar(0),(55-$zlength(message))#64+1)=""
	quit message_$zchar(128)_m_$$n64big($zlength(message)*8)

rightrotate(a,n)
	;
	; Right rotate 32 bits
	;
	quit $$rightshift(a,n)+((a#(2**n))*(2**(32-n)))

rightshift(a,n)
	;
	; Right shift 32 bits
	;
	quit a\(2**n)

not(a)
	;
	; NOT 32 bits
	;
	quit 4294967295-a

xor(a,b)
	;
	; XOR 32 bits
	new x,i
	set x=0
	for i=1:1:32 set x=(x\2)+(((a+b)#2)*2147483648),a=a\2,b=b\2
	quit x

and(a,b)
	;
	; AND 32 bits
	;
	new x,i
	set x=0
	for i=1:1:32 set x=(x\2)+((((a#2)+(b#2))\2)*2147483648),a=a\2,b=b\2
	quit x

read4bytes(message,offset)
	;
	; Return the big-endian 32 bits value representing the 4 bytes starting offset of message
	;
	new value,i
	set value=0
	for i=0:1:3 set value=256*value+$zascii($zextract(message,offset+i))
	quit value

n64big(n)
	;
	; Return the supplied value as a 64-bit big-endian integer
	;
	new s,i
	for i=8:-1:1 set $zextract(s,i)=$zchar(n#256),n=n\256
	quit s
