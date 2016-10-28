## Secure USB DFU1.1 bootloader for STM32 ##

### Features ###

+ Small size. Fits in 4K ROM segment.
+ USB DFU1.1 compatible
+ supports by dfu-util
+ Supports one of the following ciphers
  + ARCFOUR stream cipher
  + CHACHA20 stream cipher (C and ASM implementation)
  + RC5-32/12/128 block cipher in CBC mode (C and ASM implementation)
  + GOST R 34.12-2015 "MAGMA" block cipher in CBC mode
  + RAIDEN block cipher in CBC mode

+ Different interfaces for flash and eeprom programming

+ Software for firmaware encryption/decription included

+ STM32 family support
  + STM32L0x2

### Mini how-to ###

1. Configure bootloader
  + check config.h 

2. Building bootloader
  + prerequisites
    + arm-none-eabi-gcc toolset v4.9 or later to build bootloader
	+ gcc toolset to build fwcrypt software
	+ optional st-util toolset
  + *make all* to build bootloader and firmware encryption software
  + *make bootloader* to build bootloader firmware
  + *make crypter* to build encryption software
  + *make program* to flash bootloader using st-flash

3. Adjusting user application linker script
  Set ROM ORIGIN to __app_start (check bootloader map. usually 0x08001000)
  Adjust ROM LENGTH

4. Encrypting/decryptiond user application firmware

  To encrypt firmware use: fwcrypt -e infile.bin outfile.bin

  To decrypt firmware use: fwcrypt -d infile.bin outfile.bin

  Only binaries supported at this moment.
  
5. Using dfu-util

  To flash encrypted firmware: dfu-util -a 0 -D firmware.bin 

  To flash encrypted eeprom data: dfu-util -a 1 -D eeprom.bin

  To retrieve encrypted firmware: dfu-util -a 0 -U firmware.bin

  To retrieve encrypted eeprom data: dfu-util -a 1 -U eeprom.bin
  
6. Activating bootloader
  + write DFU_BOOTKEY to DFU_BOOTKEY_ADDR (usually on RAM top) and make a reset
  + tie DFU_BOOTSTRAP_PIN low on startup
 
7. Returning to user application
  + send USB RESET to device in DFU mode
  + reset device using HW reset
 
 ### Todo ###
 + Add "autoseal" feature to set prtection level 2 on bootloader start
 