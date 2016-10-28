#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#include "../config.h"
#include "crypto.h"



static const char *shelp = "Usage: encrypter [option] infile outfile\n" \
                           "\t -e Encrypt file\n" \
                           "\t -d Decrypt file\n";

static const char *sferr = "Error: unable to open file %s\n";

static const uint8_t key[] = {DFU_AES_KEY};


static int help(void) {
    printf(shelp);
    return -1;
}



static int file_crypt(char *stro, char *stri, int dir) {


    uint32_t buff[0x100];
    uint32_t bytes = 0;
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
    do {
        size_t inbytes = fread(buff, 1, sizeof(buff), fi);
      
	inbytes = ((inbytes + (CRYPTO_BLKSIZE - 1)) / CRYPTO_BLKSIZE) * CRYPTO_BLKSIZE;

#if defined(DFU_USE_CIPHER)

        if (dir == 1) {
            aes_encrypt(buff, buff, (int)inbytes);
        } else {
            aes_decrypt(buff, buff, (int)inbytes);
        }
#endif
        bytes += inbytes;
        size_t outbytes = fwrite(buff, 1, inbytes, fo);
	
    } while (!feof(fi));

    fclose(fi);
    fclose(fo);
  

    printf("Processed %u bytes use " CRYPTO_NAME "\n", bytes);
    return 0;
}





int main (int argc, char *argv[]) {

    if (argc != 4) return help();
    aes_init(key);

    if (!strcmp(argv[1], "-e")) {
        return file_crypt(argv[3], argv[2], 1);
    } else if (!strcmp(argv[1], "-d")) {
        return file_crypt(argv[3], argv[2], 0);
    } else {
        return help();
    }
}