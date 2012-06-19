/*
 *  GT.M Base64 Extension
 *  Copyright (C) 2012 Laurent Parenteau <laurent.parenteau@gmail.com>
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as
 *  published by the Free Software Foundation, either version 3 of the
 *  License, or (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#include <string.h>
#include <openssl/bio.h>
#include <openssl/buffer.h>
#include <openssl/evp.h>
#include <gtmxc_types.h>

void encode(int count, gtm_string_t *message, gtm_string_t *base64)
{
	BIO *bio, *b64;
	BUF_MEM *data;

	if (2 == count) {
		b64 = BIO_new(BIO_f_base64());
		BIO_set_flags(b64, BIO_FLAGS_BASE64_NO_NL);
		bio = BIO_new(BIO_s_mem());
		bio = BIO_push(b64, bio);
		BIO_write(bio, message->address, message->length);
		if (BIO_flush(bio)) {
			BIO_get_mem_ptr(bio, &data);
			memcpy(base64->address, data->data, data->length);
			base64->length = data->length;
		} else {
			base64->length = 0;
		}
		BIO_free_all(bio);
	}
}
