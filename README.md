## ### Secure USB DFU1.1 bootloader for STM32

#### Features
+ Small size. Fits in 4K ROM segment.
+ USB DFU1.1 compatible
+ supports by dfu-util
+ Supports one of the following ciphers
  + No encryption
  + ARCFOUR stream cipher
    + CHACHA20 stream cipher (C and ASM implementation)
    + RC5-32/12/128 block cipher in CBC mode (C and ASM implementation)
    + GOST R 34.12-2015 "MAGMA" block cipher in CBC mode
    + RAIDEN block cipher in CBC mode
+ Different interfaces for flash and eeprom programming
+ Software for firmaware encryption/decription included
+ Supported STM32 family
  + STM32L0x2

#### Usage:

#### Configure bootloader
Bootloader can be configured using preprocessor variables stored in **config.h**

#### Building bootloader
1. Prerequisites
+ GNU make
+ arm-none-eabi-gcc toolset v4.9 or later to build bootloader
+ gcc toolset to build fwcrypt software
+ optional [st-util](https://github.com/texane/stlink) toolset to program bootloader
2. Makefile targets
+ **make all** to build bootloader and firmware encryption software
+ **make bootloader** to build bootloader firmware
+ **make crypter** to build encryption software
+ **make program** to flash bootloader using st-flash

#### Adjusting user firmware
1. Adjust your linker script to set correct ROM origin and ROM length

#### Activating bootloader
+ put DFU_BOOTKEY on RAM top and make a software reset *OR*
+ tie DFU_BOOTSTRAP_PIN on DFU_BOOTSTRAP_PORT low on startup

#### Encryption/Decryption user firmware
At this moment only binary files supported

To encrypt:
````
fwcrypt -e infile.bin outfile.bin
````
To decrypt:
````
fwcrypt -d infile.bin outfile.bin
````

 #### Todo ####
 + Add "autoseal" feature to set prtection level 2 on bootloader start
 
