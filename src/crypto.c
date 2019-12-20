#include <stdint.h>
#include <string.h>
#include "config.h"

static const uint8_t key[] __attribute__((unused));
static const uint32_t nonce[] __attribute__((unused));
static uint32_t IV[] __attribute__((unused));
static void memxor(void *dst, const void *src, uint32_t sz) __attribute__((unused));

#if (DFU_CIPHER == DFU_CIPHER_RC5_A) && defined(__thumb__)
    #include "rc5_a.h"
    #define CRYPTO_KEY DFU_AES_KEY_A
    #define CRYPTO_NONCE DFU_AES_NONCE0, DFU_AES_NONCE1
    #define init(key, nonce) _rc5_init(key)
    #define encrypt(out, in) _rc5_encrypt(out, in)
    #define decrypt(out, in) _rc5_decrypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_RC5) || (DFU_CIPHER == DFU_CIPHER_RC5_A)
    #include "rc5.h"
    #define CRYPTO_KEY DFU_AES_KEY_A
    #define CRYPTO_NONCE DFU_AES_NONCE0, DFU_AES_NONCE1
    #define init(key, nonce) rc5_init(key)
    #define encrypt(out, in) rc5_encrypt(out, in)
    #define decrypt(out, in) rc5_decrypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_RAIDEN)
    #include "raiden.h"
    #define CRYPTO_KEY DFU_AES_KEY_A
    #define CRYPTO_NONCE DFU_AES_NONCE0, DFU_AES_NONCE1
    #define init(key, nonce) raiden_init(key)
    #define encrypt(out, in) raiden_encrypt(out, in)
    #define decrypt(out, in) raiden_decrypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_GOST)
    #include "gost.h"
    #define CRYPTO_KEY DFU_AES_KEY_A, DFU_AES_KEY_B
    #define CRYPTO_NONCE DFU_AES_NONCE0, DFU_AES_NONCE1
    #define init(key, nonce) gost_init(key)
    #define encrypt(out, in) gost_encrypt(out, in)
    #define decrypt(out, in) gost_decrypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_SPECK)
    #include "speck.h"
    #define CRYPTO_BLKSIZE 8
    #define CRYPTO_NAME "SPECK 64/128"
    #define CRYPTO_KEY DFU_AES_KEY_A
    #define CRYPTO_NONCE DFU_AES_NONCE0, DFU_AES_NONCE1
    #define init(key, nonce) speck_init(key)
    #define encrypt(out, in) speck_encrypt(out, in)
    #define decrypt(out, in) speck_decrypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_XTEA)
    #include "xtea.h"
    #define CRYPTO_KEY DFU_AES_KEY_A
    #define CRYPTO_NONCE DFU_AES_NONCE0, DFU_AES_NONCE1
    #define init(key, nonce) xtea_init(key)
    #define encrypt(out, in) xtea_encrypt(out, in)
    #define decrypt(out, in) xtea_decrypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_XTEA1)
    #include "xtea1.h"
    #define CRYPTO_KEY DFU_AES_KEY_A
    #define CRYPTO_NONCE DFU_AES_NONCE0, DFU_AES_NONCE1
    #define init(key, nonce) xtea1_init(key)
    #define encrypt(out, in) xtea1_encrypt(out, in)
    #define decrypt(out, in) xtea1_decrypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_ARC4)
    #include "arc4.h"
    #undef  DFU_CIPHER_MODE
    #define DFU_CIPHER_MODE -1
    #define CRYPTO_NONCE
    #define CRYPTO_KEY DFU_AES_KEY_A
    #define init(key, nonce) arc4_init(key)
    #define encrypt(out, in) arc4_crypt(out, in)
    #define decrypt(out, in) arc4_crypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_CHACHA_A) && defined(__thumb__)
    #error Cipher DISABLED
    #include "chacha_a.h"
    #define init(key) _chacha_init(key)
    #define encrypt(out, in) _chacha_crypt(out, in)
    #define decrypt(out, in) _chacha_crypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_CHACHA) || (DFU_CIPHER == DFU_CIPHER_CHACHA_A)
    #include "chacha.h"
    #undef  DFU_CIPHER_MODE
    #define DFU_CIPHER_MODE -1
    #define CRYPTO_KEY DFU_AES_KEY_A, DFU_AES_KEY_B
    #define CRYPTO_NONCE DFU_AES_NONCE0, DFU_AES_NONCE1, DFU_AES_NONCE2
    #define init(key, nonce) chacha_init(key, nonce)
    #define encrypt(out, in) chacha_crypt(out, in)
    #define decrypt(out, in) chacha_crypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_BLOWFISH)
    #include "blowfish.h"
    #define CRYPTO_KEY DFU_AES_KEY_A, DFU_AES_KEY_B
    #define CRYPTO_NONCE DFU_AES_NONCE0, DFU_AES_NONCE1
    #define init(key, nonce) blowfish_init(key)
    #define encrypt(out, in) blowfish_encrypt(out, in)
    #define decrypt(out, in) blowfish_decrypt(out, in)

#elif (DFU_CIPHER == DFU_CIPHER_RTEA)
    #include "rtea.h"
    #define CRYPTO_KEY DFU_AES_KEY_A, DFU_AES_KEY_B
    #define CRYPTO_NONCE DFU_AES_NONCE0, DFU_AES_NONCE1
    #define init(key, nonce) rtea_init(key)
    #define encrypt(out, in) rtea_encrypt(out, in)
    #define decrypt(out, in) rtea_decrypt(out, in)

#else
    #undef  DFU_CIPHER_MODE
    #define DFU_CIPHER_MODE -1
    #define CRYPTO_BLKSIZE 1
    #define CRYPTO_NAME "No encryption"
    #define CRYPTO_KEY
    #define CRYPTO_NONCE
    #define init(...)

    static void encrypt(void *out, const void* in) {
        *(uint8_t*)out = *(uint8_t*)in;
    }

    #define decrypt(out, in) encrypt(out, in);

#endif

#if (DFU_CIPHER_MODE == DFU_CIPHER_ECB) || (DFU_CIPHER_MODE == -1)
#define init_iv(...)
#else
#define init_iv(dst, src, size) memcpy((dst), (src), (size))
#endif

#if (DFU_CIPHER_MODE == DFU_CIPHER_CBC)
#define CRYPTO_MODE "CBC"
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
#define CRYPTO_MODE "PCBC"
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
#define CRYPTO_MODE "CFB"
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
#define CRYPTO_MODE "OFB"
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
#define CRYPTO_MODE "CTR"
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

#elif (DFU_CIPHER_MODE == DFU_CIPHER_ECB)
#define CRYPTO_MODE "ECB"
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
#define CRYPTO_MODE "STREAM"
static void encrypt_block(void *out, const void *in) {
    encrypt(out, in);
}

static void decrypt_block(void *out, const void *in) {
    decrypt(out, in);
}

#else
    #error Unsupported CIPHER MODE
#endif

static const uint8_t key[] = {CRYPTO_KEY};
static const uint32_t nonce[] = {CRYPTO_NONCE};
static uint32_t IV[CRYPTO_BLKSIZE / 4];

static void memxor(void *dst, const void *src, uint32_t sz) {
    while(sz--) {
        *(uint8_t*)dst++ ^= *(uint8_t*)src++;
    }
}

const char*    aes_name = CRYPTO_NAME "-" CRYPTO_MODE;
const uint32_t aes_blksize = CRYPTO_BLKSIZE;

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
