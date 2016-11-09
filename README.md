### Secure USB DFU1.1 bootloader for STM32
#### Features
+ Small size. Fits in 4K ROM segment.
+ USB DFU1.1 compatible
+ supports by [dfu-util](http://dfu-util.sourceforge.net/)
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
  + STM31L1xx

#### Usage:

#### Configure bootloader
Bootloader can be configured using preprocessor variables stored in **config.h**

#### Building bootloader
1. Prerequisites
+ GNU make
+ arm-none-eabi-gcc toolchain v4.9 or later to build bootloader
+ gcc toolchain to build fwcrypt software
+ optional [st-util](https://github.com/texane/stlink) tool to program bootloader
2. Makefile targets
+ **make mcu_target** to build bootloader
+ **make program** to flash bootloader using st-flash
+ **make crypter** to build encryption software
 
| mcu_target    | MCU                                                | remarks         |
|---------------|----------------------------------------------------|-----------------|
| stm32l100x6a  | STM32L100C6-A                                      |                 |
| stm32l100x8a  | STM32L100R8-A                                      |                 |
| stm32l100xba  | STM32L100RB-A                                      |                 |
| stm32l100xc   | STM32L100RC                                        | tested          |
| stm32l151x6a  | STM32L151C6-A, STM32L151R6-A                       |                 |
| stm32l151x8a  | STM32L151C8-A, STM32L151R8-A, STM31L151V8-A        |                 |
| stm32l151xba  | STM32L151CB-A, STM32L151RB-A, STM31L151VB-A        |                 |
| stm32l151xc   | STM32L151CC, STM32L151QC, SRM32L151RC, STM32L151UC |                 |
| stm32l151xd   | STM32L151QD, STM32L151RD, STM32L151VD, STM32L151ZD |                 |
| stm32l151xe   | STM32L151QE, STM32L151RE, STM32L151VE, STM32L151ZE |                 |
| stm32l052x8   | STM32L052K8, STM32L052T8, STM32L052C8, STM32L052R8 | tested, default |









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

