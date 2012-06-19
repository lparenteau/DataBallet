/*
 *  GT.M Digest Extension
 *  Copyright (C) 2012 Piotr Koper <piotr.koper@gmail.com>
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
#include <openssl/evp.h> /* see EVP_MAX_MD_SIZE there */
#include <gtmxc_types.h>

#define CTX_LIMIT 256
static EVP_MD_CTX * ctx[CTX_LIMIT];
static int ctx_count = 0;

static int
is_ctx (EVP_MD_CTX *c, int remove)
{
	int i;
	for (i = 0; i < ctx_count; i++)
		if (ctx[i] == c)
		{
			if (remove)
				ctx[i] = ctx[--ctx_count];
			return 1;
		}
	return 0;
}

gtm_ulong_t
init (int count, gtm_char_t* name)
{
	EVP_MD_CTX *c;
	const EVP_MD *md;

	if (count != 1)
		return 0;
	if (ctx_count > CTX_LIMIT)
		return 0;

	OpenSSL_add_all_digests ();

	if ((md = EVP_get_digestbyname (name)) == NULL)
		return 0;

	c = EVP_MD_CTX_create ();

	EVP_DigestInit_ex (c, md, NULL);
	ctx[ctx_count++] = c;
	return (gtm_ulong_t) c;
}

void
update (int count, gtm_ulong_t ref, gtm_string_t* message)
{
	EVP_MD_CTX *c = (EVP_MD_CTX *) ref;
	if (count != 2)
		return;
	if (is_ctx (c, 0) == 0)
		return;
	EVP_DigestUpdate (c, message -> address, message -> length);
}


#define hex_nibble(x) (((x) < 10) ? ((x) + '0') : ((x) + 'a' - 10))

/*
 * Today EVP_MAX_MD_SIZE is 64 (longest known is SHA512), so the preallocated
 * gtm_string_t should be at least twice this size to handle ASCII hex
 * encoded data.
 */

void
final (int count, gtm_ulong_t ref, gtm_string_t *digest /* [256] */)
{
	EVP_MD_CTX *c = (EVP_MD_CTX *) ref;
	int i;
	unsigned int length;
	unsigned char md[EVP_MAX_MD_SIZE];

	if (count != 2)
		return;
	if (is_ctx (c, 1) == 0)
	{
		digest -> length = 0;
		return;
	}

	EVP_DigestFinal_ex (c, md, &length);
	EVP_MD_CTX_destroy (c);
	EVP_cleanup ();

	/*
	 * EVP_DigestFinal_ex(..., unsigned int *length) and xc_long_t length
	 * in xc_string_t differ in signedness, but length <= EVP_MAX_MD_SIZE
	 *
	 */
	digest -> length = (xc_long_t) length * 2;

	for (i = 0; i < length; i++)
	{
		digest -> address[2*i] = hex_nibble(md[i] >> 4);
		digest -> address[2*i + 1] = hex_nibble(md[i] & 0x0f);
	}
}
