#include <stdint.h>
#include <string.h>
#include "config.h"

#if (DFU_CIPHER == DFU_CIPHER_RC5_A) && defined(__thumb__)
    #include "rc5_a.h"
    #define CIPHER_KEY DFU_AES_KEY_A
    #define init(key) _rc5_init(key)
    #define encrypt(out, in, b) _rc5_encrypt(out, in, b)
    #define decrypt(out, in, b) _rc5_decrypt(out, in, b)

#elif (DFU_CIPHER == DFU_CIPHER_RC5) || (DFU_CIPHER == DFU_CIPHER_RC5_A)
    #include "rc5.h"
    #define CRYPTO_KEY DFU_AES_KEY_A
    #define init(key, nonce) rc5_init(key)
    #define encrypt(out, in) rc5_encrypt(out, in)
    #define decrypt(out, in) rc5_decrypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_RAIDEN)
    #include "raiden.h"
    #define init(key) raiden_init(key)
    #define encrypt(out, in) raiden_encrypt(out, in)
    #define decrypt(out, in) raiden_decrypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_GOST)
    #include "gost.h"
    #define init(key) gost_init(key)
    #define encrypt(out, in) gost_encrypt(out, in)
    #define decrypt(out, in) gost_decrypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_SPECK)
    #include "speck.h"
    #define init(key) speck_init(key)
    #define encrypt(out, in) speck_encrypt(out, in)
    #define decrypt(out, in) speck_decrypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_XTEA)
    #include "xtea.h"
    #define init(key) xtea_init(key)
    #define encrypt(out, in) xtea_encrypt(out, in)
    #define decrypt(out, in) xtea_decrypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_XTEA1)
    #include "xtea.h"
    #define init(key) xtea_init(key)
    #define encrypt(out, in) xtea_encrypt(out, in)
    #define decrypt(out, in) xtea_decrypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_ARC4)
    #include "arc4.h"
    #undef  DFU_CIPHER_MODE
    #define DFU_CIPHER_MODE -1
    #define CRYPTO_KEY DFU_AES_KEY_A
    #define init(key, nonce) arc4_init(key)
    #define encrypt(out, in) arc4_crypt(out, in)
    #define decrypt(out, in) arc4_crypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_CHACHA_A) && defined(__thumb__)
    #include "chacha_a.h"
    #define init(key) _chacha_init(key)
    #define encrypt(out, in) _chacha_crypt(out, in)
    #define decrypt(out, in) _chacha_crypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_CHACHA) || (DFU_CIPHER == DFU_CIPHER_CHACHA_A)
    #include "chacha.h"
    #define init(key) chacha_init(key)
    #define encrypt(out, in) chacha_crypt(out, in)
    #define decrypt(out, in) chacha_crypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_BLOWFISH)
    #include "blowfish.h"
    #define CRYPTO_KEY DFU_AES_KEY_A, DFU_AES_KEY_B
    #define init(key, nonce) blowfish_init(key)
    #define encrypt(out, in) blowfish_encrypt(out, in)
    #define decrypt(out, in) blowfish_decrypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_RTEA)
    #include "rtea.h"
    #define init(key) rtea_init(key)
    #define encrypt(out, in) rtea_encrypt(out, in)
    #define decrypt(out, in) rtea_decrypt(out, in)

#else
    #undef DFU_USE_CIPHER
    #define CRYPTO_BLKSIZE 1
    #define CRYPTO_NAME "No encryption"
    #define aes_init(...)
    #define aes_encrypt(...)
    #define aes_decrypt(...)
#endif


static const uint8_t key[] = {CRYPTO_KEY};

#if (DFU_CIPHER_MODE == DFU_CIPHER_ECB) || (DFU_CIPHER_MODE == -1)

#define init_iv(dest, src, size)

#else
static uint32_t IV[CRYPTO_BLKSIZE / 4];
static const uint32_t nonce[2] = {DFU_AES_NONCE0, DFU_AES_NONCE1};

static void memxor(void *dst, const void *src, uint32_t sz) {
    while(sz--) {
        *(uint8_t*)dst++ ^= *(uint8_t*)src++;
    }
}

#define init_iv(dst, src, size) memcpy((dst), (src), (size))

#endif


#if (DFU_CIPHER_MODE == DFU_CIPHER_CBC)
char* aes_name = CRYPTO_NAME "-CBC";
static void encrypt_block(void *out, const void *in) {
    uint32_t TB[CRYPTO_BLKSIZE / 4];
    memcpy(TB, in, CRYPTO_BLKSIZE);
    memxor(TB, IV, CRYPTO_BLKSIZE);
    encrypt(IV, TB);
    memcpy(out, IV, CRYPTO_BLKSIZE);
}

static void decrypt_block(void *out, const void *in) {
    uint32_t TB[CRYPTO_BLKSIZE / 4];
    memcpy(TB, in, CRYPTO_BLKSIZE);
    decrypt(TB, TB);
    memxor(TB, IV, CRYPTO_BLKSIZE);
    memcpy(IV, in, CRYPTO_BLKSIZE);
    memcpy(out, TB, CRYPTO_BLKSIZE);
}

#elif (DFU_CIPHER_MODE == DFU_CIPHER_PCBC)
char* aes_name = CRYPTO_NAME "-PCBC";
static void encrypt_block(void *out, const void *in) {
    uint32_t TB[CRYPTO_BLKSIZE / 4];
    memcpy(TB, in, CRYPTO_BLKSIZE);
    memxor(IV, TB, CRYPTO_BLKSIZE);
    encrypt(IV, IV);
    memcpy(out, IV, CRYPTO_BLKSIZE);
    memxor(IV, TB, CRYPTO_BLKSIZE);
}

static void decrypt_block(void *out, const void *in) {
    uint32_t TB[CRYPTO_BLKSIZE / 4];
    memcpy(TB, in, CRYPTO_BLKSIZE);
    decrypt(TB, TB);
    memxor(TB, IV, CRYPTO_BLKSIZE);
    memcpy(IV, in, CRYPTO_BLKSIZE);
    memxor(IV, TB, CRYPTO_BLKSIZE);
    memcpy(out, TB, CRYPTO_BLKSIZE);
}

#elif (DFU_CIPHER_MODE == DFU_CIPHER_CFB)
char* aes_name = CRYPTO_NAME "-CFB";
static void encrypt_block(void *out, const void *in) {
    encrypt(IV, IV);
    memxor(IV, in, CRYPTO_BLKSIZE);
    memcpy(out, IV, CRYPTO_BLKSIZE);
}

static void decrypt_block(void *out, const void *in) {
    uint32_t TB[CRYPTO_BLKSIZE / 4];
    encrypt(TB, IV);
    memcpy(IV, in, CRYPTO_BLKSIZE);
    memxor(TB, IV, CRYPTO_BLKSIZE);
    memcpy(out, TB, CRYPTO_BLKSIZE);
}

#elif (DFU_CIPHER_MODE == DFU_CIPHER_OFB)
char* aes_name = CRYPTO_NAME "-OFB";
static void encrypt_block(void *out, const void *in) {
    uint8_t TB[CRYPTO_BLKSIZE] __attribute__((aligned(4)));
    encrypt(IV, IV);
    memcpy(TB, IV, CRYPTO_BLKSIZE);
    memxor(TB, in, CRYPTO_BLKSIZE);
    memcpy(out, TB, CRYPTO_BLKSIZE);
}

static void decrypt_block(void *out, const void *in) {
    uint8_t TB[CRYPTO_BLKSIZE] __attribute__((aligned(4)));
    encrypt(IV, IV);
    memcpy(TB, in, CRYPTO_BLKSIZE);
    memxor(TB, IV, CRYPTO_BLKSIZE);
    memcpy(out, TB, CRYPTO_BLKSIZE);
}

#elif (DFU_CIPHER_MODE == DFU_CIPHER_CTR)
char* aes_name = CRYPTO_NAME "-CTR";
static void encrypt_block(void *out, const void *in) {
    uint32_t TB[CRYPTO_BLKSIZE / 4];
    encrypt(TB, IV);
    memxor(TB, in, CRYPTO_BLKSIZE);
    memcpy(out, TB, CRYPTO_BLKSIZE);
    IV[0]++;
}

static void decrypt_block(void *out, const void *in) {
    encrypt_block(out, in);
}

#elif (DFU_CIPHER_MODE == DFU_MODE_ECB)
char* aes_name = CRYPTO_NAME "-ECB";
static void encrypt_block(void *out, const void *in) {
    uint32_t TB[CRYPTO_BLKSIZE / 4];
    memcpy(TB, in, CRYPTO_BLKSIZE);
    encrypt(TB, TB);
    memcpy(out, TB, CRYPTO_BLKSIZE);
}

static void decrypt_block(void *out, const void *in) {
    uint32_t TB[CRYPTO_BLKSIZE / 4];
    memcpy(TB, in, CRYPTO_BLKSIZE);
    decrypt(TB, TB);
    memcpy(out, TB, CRYPTO_BLKSIZE);
}

#elif (DFU_CIPHER_MODE == -1)
char* aes_name = CRYPTO_NAME "-STREAM";

static void encrypt_block(void *out, const void *in) {
    encrypt(out, in);
}

static void decrypt_block(void *out, const void *in) {
    decrypt(out, in);
}

#else
    #error Unsupported CIPHER MODE
#endif


uint32_t aes_blksize = CRYPTO_BLKSIZE;

void aes_init(void) {
    init_iv(IV, nonce, CRYPTO_BLKSIZE);
    init(key, nonce);
}

void aes_encrypt(void *out, const void *in, int32_t sz) {
    while(sz > 0) {
        encrypt_block(out, in);
        out += CRYPTO_BLKSIZE;
        in += CRYPTO_BLKSIZE;
        sz -= CRYPTO_BLKSIZE;
    }
}

void aes_decrypt(void *out, const void *in, int32_t sz) {
    while(sz > 0) {
        decrypt_block(out, in);
        out += CRYPTO_BLKSIZE;
        in += CRYPTO_BLKSIZE;
        sz -= CRYPTO_BLKSIZE;
    }
}
