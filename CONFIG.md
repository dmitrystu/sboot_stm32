## Configuring bootloader
The bootloader can be configured by overriding defaults through parameters passed to make.
+ Use external file to override default settings
```
make DFU_USER_CONFIG=userconfig.h <targets>
```
+ Override settings directly
```
make DFU_BOOTSTRAP_PIN=2 DFU_CIPHER=DFU_CIPHER_XTEA DFU_VERIFY_CHECKSUM=FNV1A64 <targets>
```
You can find configuration parameters in the following tables. Defaults marked **bold**.


### Table 1. Generic config
|Parameter           | Description                         | Values/Types                   | Notes                   |
|--------------------|-------------------------------------|--------------------------------|-------------------------|
|DFU_USER_CONFIG     | Defines file with overrides         | filename                       | **not defined**
|DFU_DNLOAD_NOSYNC   | Disables DFU SYNC state             | **_ENABLE**/_DISABLE           |                         |
|DFU_INTF_EEPROM     | Enables EEPROM interface            | _ENABLE/_DISABLE/**_AUTO**     |                         |
|DFU_CAN_UPLOAD      | Enables uploads from device         | **_ENABLE**/_DISABLE           |                         |
|DFU_DETACH          | Enables DFU_DETACH command          | **_ENABLE**/_DISABLE           | Issues RESET on detach  |
|DFU_VERIFY_CHECKSUM | Enables checksum verification       | See Table 2                    | **_DISABLE**            |
|DFU_VENDOR_ID       | USB Device VID                      | UINT16                         | **0x0483**              |
|DFU_DEVICE_ID       | USB Device DID                      | UINT16                         | **0xDF11**              |
|DFU_STR_MANUF       | USB Device manufacturer string      | ASCII/UTF-16                   | **"Your company name"** |
|DFU_STR_PRODUCT     | USB Device product string           | ASCII/UTF-16                   | **"Secure bootloader"** |
|DFU_DSC_CONFIG      | Enables Device configuration string | _ENABLE/**_DISABLE**           |                         |
|DFU_STR_CONFIG      | Device configuration string         | ASCII/UTF-16                   | **"DFU"**               |
|DFU_DSC_FLASH       | Enables flash interface string      | **_ENABLE**/_DISABLE           |                         |
|DFU_STR_FLASH       | Flash interface string              | ASCII/UTF-16                   | **"Internal flash"**    |
|DFU_DSC_EEPROM      | Enables EEPROM interface string     | **_ENABLE**/_DISABLE           |                         |
|DFU_STR_EEPROM      | EEPROM interface string             | ASCII/UTF-16                   | **"Internal EEPROM"**   |
|DFU_POLL_TIMEOUT    | DFU poll time (ms)                  | > 0                            | **20**                  |
|DFU_DETACH_TIMEOUT  | DFU detach timeout (ms)             | > 0                            | **200**                 |
|DFU_BLOCKSZ         | DFU block size (bytes)              | must fit cipher block size     | **0x80**                |
|DFU_BOOTKEY         | DFU bootkey value                   | UINT32                         | **0x157F32D4**          |
|DFU_BOOTKEY_ADDR    | Address of the bootkey in RAM       | RAM ADDRESS/_DISABLE/**_AUTO** | **on the top of stack** |
|DFU_BOOTSTRAP_GPIO  | DFU bootstrap port                  | GPIOx/_DISABLE                 | **GPIOA**               |
|DFU_BOOTSTRAP_PIN   | DFU bootstarp pin                   | 0-15                           | **1**                   |
|DFU_BOOTSTRAP_LEVEL | Level on bootstrap pin to activate  | **_LOW**/_HIGH                 |                         |
|DFU_BOOTSTRAP_PULL  | Bootstrap pin pullup control        | _DISABLE/**_AUTO**/_LOW/_HIGH  |                         |
|DFU_DBLRESET_MS     | Doublereset activation time (ms)    | TIMEOUT/_DISABLE               | **300**                 |
|DFU_APP_START       | Start address for user code         | ROM ADDRESS/**_AUTO**          | must be page aligned    |
|DFU_APP_SIZE        | User application max size           | AMMOUNT/**_AUTO**              | up to the ROM end       |
|DFU_CIPHER          | Type of ciper                       | See Table 3                    | **DFU_CIPHER_RC5**      |
|DFU_CIPHER_MODE     | Cipher mode of operation            | See Table 4                    | **DFU_CIPHER_CBC**      |
|DFU_AES_KEY_128     | 128-bit cipher key                  | Comma separated bytes          |                         |
|DFU_AES_KEY_256     | 256-bit cipher key                  | Comma separated bytes          |                         |
|DFU_AES_IV_64       | 64-bit cipher IV                    | Comma separated bytes          |                         |
|DFU_AES_IV_96       | 96-bit cipher IV                    | Comma separated bytes          | Used for the CHACHA     |
|DFU_AES_IV_128      | 128-bit cipher IV                   | Comma separated bytes          |                         |

### Table 2. Available Checksums
*Note:* Firmware checksum will be checked on every startup. Bootloader will be activated if no correct firmware found. It may take a lot of time.
|Checksum   | Description                                                                   |
|-----------|-------------------------------------------------------------------------------|
|_DISABLE   | Disable firmware verification                                                 |
|CRC32FAST  | Lookup table based crc32 algorithm, consumes 1Kb of RAM for the table         |
|CRC32SMALL | Permutation based crc32 algorithm, no lookup table required but slower        |
|FNV1A32    | Fowler–Noll–Vo 32 bit Hash                                                    |
|FNV1A64    | Fowler–Noll–Vo 64 bit Hash                                                    |
|CRC64FAST  | Lookup table based crc64 algorithm, consumes 2Kb of RAM for the table         |
|CRC64SMALL | Permutation based crc64 algorithm, no lookup table required but extremly slow |


### Table 3. Available Ciphers
|Cipher Type/Mode    | Description                  | Block size | Key Size | IV size | Notes                    |
|--------------------|------------------------------|------------|----------|---------|--------------------------|
|_DISABLE            | Disable encryption           |            |          |         |                          |
|DFU_CIPHER_ARC4     | Rivest RC-4                  | Stream     | 128      | N/A     | Unsafe                   |
|DFU_CIPHER_CHACHA   | RFC7539-CHACHA20             | Stream     | 256      | 96      |                          |
|DFU_CIPHER_CHACHA_A | RFC7539-CHACHA20             | Stream     | 256      | 96      | THUMB ASM version        |
|DFU_CIPHER_GOST     | GOST R 34.12-2015 MAGMA      |  64        | 256      | 64      | treat data as LE32       |
|DFU_CIPHER_RAIDEN   | RAIDEN                       |  64        | 128      | 64      |                          |
|DFU_CIPHER_RC5      | Rivest RC5-32/12/128         |  64        | 128      | 64      |                          |
|DFU_CIPHER_RC5_A    | Rivest RC5-32/12/128         |  64        | 128      | 64      | THUMB ASM version        |
|DFU_CIPHER_SPECK    | SPECK 64/128                 |  64        | 128      | 64      |                          |
|DFU_CIPHER_XTEA     | XTEA                         |  64        | 128      | 64      | treat data as LE64       |
|DFU_CIPHER_XTEA1    | XTEA-1                       |  64        | 128      | 64      | treat data as LE64       |
|DFU_CIPHER_BLOWFISH | Blowfish                     |  64        | 256      | 64      | Uses xorshift instead PI |
|DFU_CIPHER_RTEA     | Ruptor's TEA or Repaired TEA |  64        | 256      | 64      |                          |
|DFU_CIPHER_RC6      | Rivest RC6-32/20/16          |  128       | 128      | 128     |                          |
|DFU_CIPHER_RC6_A    | Rivest RC6-32/20/16          |  128       | 128      | 128     | THUMB ASM verison        |
|DFU_CIPHER_RIJNDAEL | Rijndael AES-128/192/256     |  128       | 128      | 128     | 128-bit key by default   |

### Table 4. Available Block Cipher Modes of Operation
|Cipher mode     | Description                              |
|----------------|------------------------------------------|
|DFU_CIPHER_ECB  | Electronic Codebook (ECB)                |
|DFU_CIPHER_CBC  | Cipher Block Chaining (CBC)              |
|DFU_CIPHER_PCBC | Propagating Cipher Block Chaining (PCBC) |
|DFU_CIPHER_CFB  | Cipher Feedback (CFB)                    |
|DFU_CIPHER_OFB  | Output Feedback (OFB)                    |
|DFU_CIPHER_CTR  | Counter (CTR) (simply IV increment)      |