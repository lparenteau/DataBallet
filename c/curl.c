/*
 *  GT.M CURL Extension
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
#include <curl/curl.h>
#include <gtmxc_types.h>

void unescape(int count, gtm_string_t *val, gtm_string_t *unescaped)
{
	CURL *curl;
	char *ret;
	int length;

	if (2 == count) {
		curl = curl_easy_init();
		ret = curl_easy_unescape(curl, val->address, val->length, &length);
		unescaped->length = length;
		memcpy(unescaped->address, ret, unescaped->length);
		curl_free(ret);
		curl_easy_cleanup(curl);
	}
}

void escape(int count, gtm_string_t *val, gtm_string_t *escaped)
{
	CURL *curl;
	char *ret;
	if (2 == count) {
		curl = curl_easy_init();
		ret = curl_easy_escape(curl, val->address, val->length);
		escaped->length = strlen(ret);
		memcpy(escaped->address, ret, escaped->length);
		curl_easy_cleanup(curl);
	}
}
