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

#define MAX_LENGTH 256

void encode(int count, gtm_pointertofunc_t gtm_malloc, gtm_pointertofunc_t gtm_free, gtm_string_t *message, gtm_string_t *base64)
{
	BIO *bio, *b64;
	BUF_MEM *data;

	if (4 == count) {
		if ((b64 = BIO_new(BIO_f_base64()))) {
			BIO_set_flags(b64, BIO_FLAGS_BASE64_NO_NL);
			if ((bio = BIO_new(BIO_s_mem()))) {
				b64 = BIO_push(b64, bio);
				BIO_write(b64, message->address, message->length);
				if (BIO_flush(b64)) {
					BIO_get_mem_ptr(b64, &data);
					if (data->length > MAX_LENGTH) {
						((void (*)(void *))gtm_free)(base64->address);
						base64->address = ((void *(*)(int))gtm_malloc)(data->length);
					}
					memcpy(base64->address, data->data, data->length);
					base64->length = data->length;
				} else {
					base64->length = 0;
				}
			} else {
				base64->length = 0;
			}
			BIO_free_all(b64);
		} else {
			base64->length = 0;
		}
	}
}
