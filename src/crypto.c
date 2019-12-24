#include <stdint.h>
#include <string.h>
#include "config.h"

static const uint8_t key[] __attribute__((unused));
static const uint32_t nonce[] __attribute__((unused));
static uint32_t IV[] __attribute__((unused));
static void memxor(void *dst, const void *src, uint32_t sz) __attribute__((unused));

#if (DFU_CIPHER == DFU_CIPHER_RC5_A) && defined(__thumb__)
    #include "rc5_a.h"
    #define CRYPTO_BLKSIZE 8
    #define CRYPTO_NAME "RC5-64/12/128"
    #define CRYPTO_KEY DFU_AES_KEY_A
    #define CRYPTO_NONCE DFU_AES_NONCE0, DFU_AES_NONCE1
    #define crypto_init(key, nonce) _rc5_init(key)
    #define crypto_encrypt(out, in) _rc5_encrypt(out, in)
    #define crypto_decrypt(out, in) _rc5_decrypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_RC5) || (DFU_CIPHER == DFU_CIPHER_RC5_A)
    #include "rc5.h"
    #define CRYPTO_BLKSIZE 8
    #define CRYPTO_NAME "RC5-64/12/128"
    #define CRYPTO_KEY DFU_AES_KEY_A
    #define CRYPTO_NONCE DFU_AES_NONCE0, DFU_AES_NONCE1
    #define crypto_init(key, nonce) rc5_init(key)
    #define crypto_encrypt(out, in) rc5_encrypt(out, in)
    #define crypto_decrypt(out, in) rc5_decrypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_RAIDEN)
    #include "raiden.h"
    #define CRYPTO_BLKSIZE 8
    #define CRYPTO_NAME "RAIDEN-64/16/128"
    #define CRYPTO_KEY DFU_AES_KEY_A
    #define CRYPTO_NONCE DFU_AES_NONCE0, DFU_AES_NONCE1
    #define crypto_init(key, nonce) raiden_init(key)
    #define crypto_encrypt(out, in) raiden_encrypt(out, in)
    #define crypto_decrypt(out, in) raiden_decrypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_GOST)
    #include "gost.h"
    #define CRYPTO_BLKSIZE 8
    #define CRYPTO_NAME "GOST R 34.12-2015 \"MAGMA\""
    #define CRYPTO_KEY DFU_AES_KEY_A, DFU_AES_KEY_B
    #define CRYPTO_NONCE DFU_AES_NONCE0, DFU_AES_NONCE1
    #define crypto_init(key, nonce) gost_init(key)
    #define crypto_encrypt(out, in) gost_encrypt(out, in)
    #define crypto_decrypt(out, in) gost_decrypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_SPECK)
    #include "speck.h"
    #define CRYPTO_BLKSIZE 8
    #define CRYPTO_NAME "SPECK-64/27/128"
    #define CRYPTO_KEY DFU_AES_KEY_A
    #define CRYPTO_NONCE DFU_AES_NONCE0, DFU_AES_NONCE1
    #define crypto_init(key, nonce) speck_init(key)
    #define crypto_encrypt(out, in) speck_encrypt(out, in)
    #define crypto_decrypt(out, in) speck_decrypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_XTEA)
    #include "xtea.h"
    #define CRYPTO_BLKSIZE 8
    #define CRYPTO_NAME "XTEA 64/32/128"
    #define CRYPTO_KEY DFU_AES_KEY_A
    #define CRYPTO_NONCE DFU_AES_NONCE0, DFU_AES_NONCE1
    #define crypto_init(key, nonce) xtea_init(key)
    #define crypto_encrypt(out, in) xtea_encrypt(out, in)
    #define crypto_decrypt(out, in) xtea_decrypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_XTEA1)
    #include "xtea1.h"
    #define CRYPTO_BLKSIZE 8
    #define CRYPTO_NAME "XTEA-1 64/32/128"
    #define CRYPTO_KEY DFU_AES_KEY_A
    #define CRYPTO_NONCE DFU_AES_NONCE0, DFU_AES_NONCE1
    #define crypto_init(key, nonce) xtea1_init(key)
    #define crypto_encrypt(out, in) xtea1_encrypt(out, in)
    #define crypto_decrypt(out, in) xtea1_decrypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_ARC4)
    #include "arc4.h"
    #define CRYPTO_BLKSIZE 1
    #define CRYPTO_NAME "ARCFOUR"
    #undef  DFU_CIPHER_MODE
    #define DFU_CIPHER_MODE -1
    #define CRYPTO_NONCE
    #define CRYPTO_KEY DFU_AES_KEY_A
    #define crypto_init(key, nonce) arc4_init(key)
    #define crypto_encrypt(out, in) arc4_crypt(out, in)
    #define crypto_decrypt(out, in) arc4_crypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_CHACHA_A) && defined(__thumb__)
    #error Cipher DISABLED
    #include "chacha_a.h"
    #define init(key) _chacha_init(key)
    #define encrypt(out, in) _chacha_crypt(out, in)
    #define decrypt(out, in) _chacha_crypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_CHACHA) || (DFU_CIPHER == DFU_CIPHER_CHACHA_A)
    #include "chacha.h"
    #define CRYPTO_BLKSIZE 1
    #define CRYPTO_NAME    "RFC7539-CHACHA20"
    #undef  DFU_CIPHER_MODE
    #define DFU_CIPHER_MODE -1
    #define CRYPTO_KEY DFU_AES_KEY_A, DFU_AES_KEY_B
    #define CRYPTO_NONCE DFU_AES_NONCE0, DFU_AES_NONCE1, DFU_AES_NONCE2
    #define crypto_init(key, nonce) chacha_init(key, nonce)
    #define crypto_encrypt(out, in) chacha_crypt(out, in)
    #define crypto_decrypt(out, in) chacha_crypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_BLOWFISH)
    #include "blowfish.h"
    #define CRYPTO_BLKSIZE 8
    #define CRYPTO_NAME "BLOWFISH 64/16/256"
    #define CRYPTO_KEY DFU_AES_KEY_A, DFU_AES_KEY_B
    #define CRYPTO_NONCE DFU_AES_NONCE0, DFU_AES_NONCE1
    #define crypto_init(key, nonce) blowfish_init(key)
    #define crypto_encrypt(out, in) blowfish_encrypt(out, in)
    #define crypto_decrypt(out, in) blowfish_decrypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_RTEA)
    #include "rtea.h"
    #define CRYPTO_BLKSIZE 8
    #define CRYPTO_NAME "RTEA 64/64/256"
    #define CRYPTO_KEY DFU_AES_KEY_A, DFU_AES_KEY_B
    #define CRYPTO_NONCE DFU_AES_NONCE0, DFU_AES_NONCE1
    #define crypto_init(key, nonce) rtea_init(key)
    #define crypto_encrypt(out, in) rtea_encrypt(out, in)
    #define crypto_decrypt(out, in) rtea_decrypt(out, in)

#else
    #undef  DFU_CIPHER_MODE
    #define DFU_CIPHER_MODE -1
    #define CRYPTO_BLKSIZE 1
    #define CRYPTO_NAME "NONE"
    #define CRYPTO_KEY
    #define CRYPTO_NONCE
    #define crypto_init(...)

    static void crypto_encrypt(void *out, const void* in) {
        *(uint8_t*)out = *(uint8_t*)in;
    }

    #define crypto_decrypt(out, in) crypto_encrypt(out, in);

#endif

#if !defined(DFU_CIPHER_MODE) || (DFU_CIPHER_MODE == DFU_CIPHER_CBC)
#define CRYPTO_MODE "-CBC"
#define crypto_init_iv(dst, src, size) memcpy((dst), (src), (size))
static void encrypt_block(void *out, const void *in) {
    uint32_t TB[CRYPTO_BLKSIZE / 4];
    memcpy(TB, in, CRYPTO_BLKSIZE);
    memxor(TB, IV, CRYPTO_BLKSIZE);
    crypto_encrypt(IV, TB);
    memcpy(out, IV, CRYPTO_BLKSIZE);
}

static void decrypt_block(void *out, const void *in) {
    uint32_t TB[CRYPTO_BLKSIZE / 4];
    memcpy(TB, in, CRYPTO_BLKSIZE);
    crypto_decrypt(TB, TB);
    memxor(TB, IV, CRYPTO_BLKSIZE);
    memcpy(IV, in, CRYPTO_BLKSIZE);
    memcpy(out, TB, CRYPTO_BLKSIZE);
}

#elif (DFU_CIPHER_MODE == DFU_CIPHER_PCBC)
#define CRYPTO_MODE "-PCBC"
#define crypto_init_iv(dst, src, size) memcpy((dst), (src), (size))
static void encrypt_block(void *out, const void *in) {
    uint32_t TB[CRYPTO_BLKSIZE / 4];
    memcpy(TB, in, CRYPTO_BLKSIZE);
    memxor(IV, TB, CRYPTO_BLKSIZE);
    crypto_encrypt(IV, IV);
    memcpy(out, IV, CRYPTO_BLKSIZE);
    memxor(IV, TB, CRYPTO_BLKSIZE);
}

static void decrypt_block(void *out, const void *in) {
    uint32_t TB[CRYPTO_BLKSIZE / 4];
    memcpy(TB, in, CRYPTO_BLKSIZE);
    crypto_decrypt(TB, TB);
    memxor(TB, IV, CRYPTO_BLKSIZE);
    memcpy(IV, in, CRYPTO_BLKSIZE);
    memxor(IV, TB, CRYPTO_BLKSIZE);
    memcpy(out, TB, CRYPTO_BLKSIZE);
}

#elif (DFU_CIPHER_MODE == DFU_CIPHER_CFB)
#define CRYPTO_MODE "-CFB"
#define crypto_init_iv(dst, src, size) memcpy((dst), (src), (size))
static void encrypt_block(void *out, const void *in) {
    crypto_encrypt(IV, IV);
    memxor(IV, in, CRYPTO_BLKSIZE);
    memcpy(out, IV, CRYPTO_BLKSIZE);
}

static void decrypt_block(void *out, const void *in) {
    uint32_t TB[CRYPTO_BLKSIZE / 4];
    crypto_encrypt(TB, IV);
    memcpy(IV, in, CRYPTO_BLKSIZE);
    memxor(TB, IV, CRYPTO_BLKSIZE);
    memcpy(out, TB, CRYPTO_BLKSIZE);
}

#elif (DFU_CIPHER_MODE == DFU_CIPHER_OFB)
#define CRYPTO_MODE "-OFB"
#define crypto_init_iv(dst, src, size) memcpy((dst), (src), (size))
static void encrypt_block(void *out, const void *in) {
    uint32_t TB[CRYPTO_BLKSIZE / 4];
    crypto_encrypt(IV, IV);
    memcpy(TB, IV, CRYPTO_BLKSIZE);
    memxor(TB, in, CRYPTO_BLKSIZE);
    memcpy(out, TB, CRYPTO_BLKSIZE);
}

static void decrypt_block(void *out, const void *in) {
    uint32_t TB[CRYPTO_BLKSIZE / 4];
    crypto_encrypt(IV, IV);
    memcpy(TB, in, CRYPTO_BLKSIZE);
    memxor(TB, IV, CRYPTO_BLKSIZE);
    memcpy(out, TB, CRYPTO_BLKSIZE);
}

#elif (DFU_CIPHER_MODE == DFU_CIPHER_CTR)
#define CRYPTO_MODE "-CTR"
#define crypto_init_iv(dst, src, size) memcpy((dst), (src), (size))
static void encrypt_block(void *out, const void *in) {
    uint32_t TB[CRYPTO_BLKSIZE / 4];
    crypto_encrypt(TB, IV);
    memxor(TB, in, CRYPTO_BLKSIZE);
    memcpy(out, TB, CRYPTO_BLKSIZE);
    IV[0]++;
}

static void decrypt_block(void *out, const void *in) {
    encrypt_block(out, in);
}

#elif (DFU_CIPHER_MODE == DFU_CIPHER_ECB)
#define CRYPTO_MODE "-ECB"
#define crypto_init_iv(...)
static void encrypt_block(void *out, const void *in) {
    uint32_t TB[CRYPTO_BLKSIZE / 4];
    memcpy(TB, in, CRYPTO_BLKSIZE);
    crypto_encrypt(TB, TB);
    memcpy(out, TB, CRYPTO_BLKSIZE);
}

static void decrypt_block(void *out, const void *in) {
    uint32_t TB[CRYPTO_BLKSIZE / 4];
    memcpy(TB, in, CRYPTO_BLKSIZE);
    crypto_decrypt(TB, TB);
    memcpy(out, TB, CRYPTO_BLKSIZE);
}

#elif (DFU_CIPHER_MODE == -1)
#define CRYPTO_MODE "-STREAM"
#define crypto_init_iv(...)
static void encrypt_block(void *out, const void *in) {
    crypto_encrypt(out, in);
}

static void decrypt_block(void *out, const void *in) {
    crypto_decrypt(out, in);
}

#else
    #error Unsupported CIPHER MODE
#endif

#pragma message "Using " CRYPTO_NAME CRYPTO_MODE " cipher"

static const uint8_t key[] = {CRYPTO_KEY};
static const uint32_t nonce[] = {CRYPTO_NONCE};
static uint32_t IV[CRYPTO_BLKSIZE / 4];

static void memxor(void *dst, const void *src, uint32_t sz) {
    while(sz--) {
        *(uint8_t*)dst++ ^= *(uint8_t*)src++;
    }
}

const char*    aes_name = CRYPTO_NAME CRYPTO_MODE;
const uint32_t aes_blksize = CRYPTO_BLKSIZE;

void aes_init(void) {
    crypto_init_iv(IV, nonce, CRYPTO_BLKSIZE);
    crypto_init(key, nonce);
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
