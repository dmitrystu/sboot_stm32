/* This file is the part of the STM32 secure bootloader
 *
 * Copyright ©2016 Dmitry Filimonchuk <dmitrystu[at]gmail[dot]com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *   http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "getopt.h"
#include "config.h"
#include "crypto.h"
#include "checksum.h"


static void exithelp(void) {
    printf("Usage: fwcrypt [options] infile outfile\n"
           "\t -e Encrypt (default)\n"
           "\t -d Decrypt\n"
           "\t -c Without checksum signature\n"
    );
    exit(0);
}


int main(int argc, char **argv)
{
    int dir = 1;
    int crc = 1;
    int c;

    opterr = 0;

    while ((c = getopt(argc, argv, "edch")) != -1)
        switch (c)
        {
        case 'e':
            dir = 1;
            break;
        case 'd':
            dir = 0;
            break;
        case 'c':
            crc = 0;
            break;
        case 'h':
        case '?':
            exithelp();
            break;
        default:
            exit(-1);
        }

    if ((argc - optind) != 2) exithelp();

    FILE *fi = fopen(argv[optind], "rb");
    if (fi == NULL) {
        printf("Failed to open file: %s\n", argv[optind]);
        exit(1);
    }

    optind++;

    FILE *fo = fopen(argv[optind], "wb");
    if (fo == NULL) {
        fclose(fi);
        printf("Failed to open file: %s\n", argv[optind]);
        exit(2);
    }

    fseek(fi, 0, SEEK_END);
    uint32_t length = ftell(fi);
    fseek(fi, 0, SEEK_SET);

    uint32_t *buf = malloc(length + 20);
    if (buf == NULL) {
        printf("Failed to allocate buffer. length %d\n", length);
        exit(3);
    }

    fread(buf, 1, length, fi);
    fclose(fi);

    aes_init();
    if (dir) {
#if (DFU_VERIFY_CHECKSUM != _DISABLE)
        if (crc) {
            uint32_t cs = calculate_checksum(buf, length);
            printf("Firmware length: %d, checksum: %08X\n"
                   "Addind signature.\n",
                    length, cs);

            memcpy(&((uint8_t*)buf)[length + 0], &cs, 4);
            cs = ~cs;
            memcpy(&((uint8_t*)buf)[length + 4], &cs, 4);

            printf("Validating firmware signature. ");
            uint32_t checked_length = validate_checksum(buf, length);
            if (checked_length != length) {
                printf("FAIL. Collision found at offset %d\n", checked_length);
                exit(-3);
            } else {
                printf("OK.\n");
            }
            length = length + 8;
        }
#endif

#if(DFU_CIPHER != _DISABLE)
        if (length % CRYPTO_BLKSIZE) {
            length += (CRYPTO_BLKSIZE - (length % CRYPTO_BLKSIZE));
        }
        printf("Encrypting %u bytes using " CRYPTO_NAME " cipher.\n", length);
        aes_encrypt(buf, buf, length);
#endif

    } else {

#if(DFU_CIPHER != _DISABLE)
        printf("Decrypting %u bytes using " CRYPTO_NAME " cipher.\n", length);
        aes_decrypt(buf, buf, length);
#endif

#if (DFU_VERIFY_CHECKSUM != _DISABLE)
        if (crc) {
            uint32_t checked_length = validate_checksum(buf, length);
            if (checked_length == 0) {
                printf("No valid signature found.\n");
            } else {
                printf("Valid signature found at offset %d\n", checked_length);
                length = checked_length;
            }
        }
#endif

    }

    fwrite(buf, 1, length, fo);
    fclose(fo);
    free(buf);
    return 0;
}
