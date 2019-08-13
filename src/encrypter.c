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
#include "config.h"
#include "crypto.h"
#include "checksum.h"

static const char *shelp = "Usage: encrypter [option] infile outfile\n" \
                           "\t -e Encrypt file\n" \
                           "\t -d Decrypt file\n";

static const char *sferr = "Error: unable to open file %s\n";

static int help(void) {
    printf(shelp);
    return -1;
}

static int file_crypt(char *stro, char *stri, int dir) {
    uint32_t buff[0x100];
    uint32_t bytes = 0;
    uint32_t length;
    uint32_t *inputbuffer;
    char *datapointer;

    FILE *fi = fopen(stri, "rb");
    if (fi == NULL) {
        printf(sferr, stri);
        return 1;
    }
    FILE *fo = fopen(stro, "wb");
    if (fo == NULL) {
        fclose(fi);
        printf(sferr, stro);
        return 2;
    }

    fseek(fi, 0, SEEK_END);
    length = ftell(fi);
    fseek(fi, 0, SEEK_SET);

    inputbuffer = (uint32_t *) malloc(checksum_length()+length+(sizeof(uint32_t)*2));

    fread(inputbuffer, 1, length, fi);

    fclose(fi);

#if (defined(DFU_VERIFY_CHECKSUM) && (DFU_VERIFY_CHECKSUM != _DISABLE))
    if (dir == 1) {
        length = checksum_create(inputbuffer, length);
    }
#endif

    datapointer = (char *) inputbuffer;

    aes_init();
    while (length!=0) {
        size_t inbytes;

        if (length>sizeof(buff))
            inbytes = sizeof(buff);
        else
            inbytes = length;

        memcpy(buff, datapointer, inbytes);

        datapointer += inbytes;
        length -= inbytes;

        inbytes = ((inbytes + (CRYPTO_BLKSIZE - 1)) / CRYPTO_BLKSIZE) * CRYPTO_BLKSIZE;

#if defined(DFU_USE_CIPHER)

        if (dir == 1) {
            aes_encrypt(buff, buff, (int)inbytes);
        } else {
            aes_decrypt(buff, buff, (int)inbytes);
        }
#endif
        bytes += inbytes;

        fwrite(buff, 1, inbytes, fo);
    }

    free(inputbuffer);

    fclose(fo);

    printf("Processed %u bytes use " CRYPTO_NAME "\n", bytes);
    return 0;
}





int main (int argc, char *argv[]) {
    if (argc != 4) return help();
    if (!strcmp(argv[1], "-e")) {
        return file_crypt(argv[3], argv[2], 1);
    } else if (!strcmp(argv[1], "-d")) {
        return file_crypt(argv[3], argv[2], 0);
    } else {
        return help();
    }
}
