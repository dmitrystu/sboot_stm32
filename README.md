![LNX build](https://github.com/dmitrystu/sboot_stm32/workflows/LNX%20build/badge.svg)
![WIN build](https://github.com/dmitrystu/sboot_stm32/workflows/WIN%20build/badge.svg)
![OSX build](https://github.com/dmitrystu/sboot_stm32/workflows/OSX%20build/badge.svg)
### Secure USB DFU1.1 bootloader for STM32
#### Features
+ Small size. Fits in 4K ROM segment (ASM or no encryption, otherwise a bit more).
+ USB DFU1.1 compatible
+ Supported by [dfu-util](http://dfu-util.sourceforge.net/)
+ Supported ciphers:
  + No encryption
  + ARCFOUR stream cipher
  + CHACHA20 stream cipher
  + RC5-32/12/16 block cipher (C and ASM implementation)
  + RC6-32/20/16 block cipher (C and ASM implementation)
  + GOST R 34.12-2015 "MAGMA" block cipher
  + RAIDEN block cipher
  + SPECK 64/128 block cipher
  + XTEA (classic and XTEA-1) block cipher
  + RTEA block cipher
  + BLOWFISH type block cipher
  + Rijndael AES-128/192/256 block cipher
+ Supported cipher modes for block ciphers:
  + Electronic Codebook (ECB)
  + Cipher Block Chaining (CBC)
  + Propagating CBC (PCBC)
  + Cipher Feedback (CFB)
  + Output Feedback (OFB)
  + Counter (CTR)
+ Supported firmware verification methods:
  + CRC (CRC32, CRC64)
  + Fowler-Noll-Vo (FNV-1A-32, FNV1A-64)
+ Separate interfaces for flash and EEPROM programming
+ Autoseal using RDP level 1 or 2 (prevents reading decrypted FW trough debug interface).
  Be careful when you set RDP to level 2. **This operation is irreversible and disables
  all debug functions and option bytes programming.**
+ Software for firmware encryption/decryption included
+ Supported STM32 families:
  + STM32L0x2
  + STM32L1xx
  + STM32L476xx (OTG FS in device mode)
  + STM32F103
  + STM32F105, STM32F107 (OTG FS in device mode)
  + STM32F0 series
  + STM32F3 series
  + STM32F4 series
  + STM32G4 series

#### Generic flow

![Generic Flow](https://mermaid.ink/img/eyJjb2RlIjoiZ3JhcGggVERcbiAgICBzdGFydChbUkVTRVRdKVxuICAgIGdvYXBwKFtBY3RpdmF0ZSBhcHBsaWNhdGlvbl0pXG4gICAgZ29ib290KFtBY3RpdmF0ZSBib290bG9hZGVyXSlcbiAgICBib290a2V5MXt7Ym9vdGtleSBtYXRjaCBpbnZlcnRlZD99fVxuICAgIGJvb3RrZXkye3tib290a2V5IG1hdGNoIG9uIHN0YXJ0P319XG4gICAgd2FpdChTZXQgYm9vdGtleSBhbmQgd2FpdCBzb21lIHRpbWUpXG4gICAgY2xyYm9vdGtleVtDbGVhciBib290a2V5XVxuICAgIHNldGNsb2NrW1NldHVwIFJDQ11cbiAgICBjaGVja3BpbihTZXR1cCBhbmQgY2hlY2sgcGluKVxuICAgIHNldHJlZ3NbU2V0dXAgTVNQIGFuZCBWVE9SXVxuICAgIGNzdmVyaWZ5KFZlcmlmeSBhcHBsaWNhdGlvbiBzaWduYXR1cmUpXG4gICAgc2V0aW52Ym9vdGtleVtTZXQgaW52ZXJ0ZWQgYm9vdGtleV1cblxuICAgIHN0YXJ0LS0-Ym9vdGtleTFcbiAgICBib290a2V5MS0tWWVzLS0-c2V0cmVnc1xuICAgIHNldHJlZ3MtLT5nb2FwcFxuICAgIGJvb3RrZXkxLS0-d2FpdFxuICAgIHdhaXQtLT5jbHJib290a2V5XG4gICAgY2xyYm9vdGtleS0tPnNldGNsb2NrXG4gICAgd2FpdC0uaGFyZHdhcmUgcmVzZXQuLT5zdGFydFxuICAgIHNldGNsb2NrLS0-Ym9vdGtleTJcbiAgICBib290a2V5Mi0tWWVzLS0-Z29ib290XG4gICAgYm9vdGtleTItLT5jaGVja3BpblxuICAgIGNoZWNrcGluLS1QaW4gYWN0aXZlLS0-Z29ib290XG4gICAgY2hlY2twaW4tLT5jc3ZlcmlmeVxuICAgIGNzdmVyaWZ5LS1Ob3QgbWF0Y2gtLT5nb2Jvb3RcbiAgICBjc3ZlcmlmeS0tPnNldGludmJvb3RrZXlcbiAgICBzZXRpbnZib290a2V5LS5OVklDIHJlc2V0Li0-c3RhcnQiLCJtZXJtYWlkIjp7InRoZW1lIjoiZGVmYXVsdCJ9LCJ1cGRhdGVFZGl0b3IiOmZhbHNlfQ)

#### Usage:

#### Configuring bootloader
The bootloader can be configured through the make parameters. See CONFIG.md for details.

#### Building bootloader
1. Prerequisites
+ GNU make
+ arm-none-eabi-gcc toolchaipren v4.9 or later to build bootloader
+ gcc toolchain to build fwcrypt software
+ [CMSIS V4](https://github.com/ARM-software/CMSIS) or [CMSIS V5](https://github.com/ARM-software/CMSIS_5).
+ Device peripheral access layer header files for STM32. See [Vendor Template](https://github.com/ARM-software/CMSIS/tree/master/Device/_Template_Vendor) for details.
+ [stm32.h](https://github.com/dmitrystu/stm32h) STM32 universal header
+ optional [st-util](https://github.com/texane/stlink) tool to program bootloader
2. Makefile targets
+ **make prerequisites** to download required libs and headers
+ **make mcu_target** to build bootloader
+ **make program** to flash bootloader using st-flash
+ **make crypter** to build encryption software
3. Makefile and environmental variables

| Variable | Default Value                       | Description                         |
|----------|-------------------------------------|-------------------------------------|
| CMSIS    | CMSIS                               | path to CMSIS root folder           |
| CMSISDEV | $(CMSIS)/Device                     | path to CMSIS device folder         |
| OUTDIR   | build                               | output folder for binaries          |
| FWNAME   | firmware                            | name for bootloader binary          |
| SWNAME   | fwcrypt                             | name for encrypter binary           |

4. MCU targets

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
| stm32l152x6a  | STM32L152C6-A, STM32L152R6-A                       |                 |
| stm32l152x8a  | STM32L152C8-A, STM32L152R8-A, STM31L152V8-A        |                 |
| stm32l152xba  | STM32L152CB-A, STM32L152RB-A, STM31L152VB-A        |                 |
| stm32l152xc   | STM32L152CC, STM32L152QC, SRM32L152RC, STM32L152UC |                 |
| stm32l152xd   | STM32L152QD, STM32L152RD, STM32L152VD, STM32L152ZD |                 |
| stm32l152xe   | STM32L152QE, STM32L152RE, STM32L152VE, STM32L152ZE |                 |
| stm32l162xc   | STM32L162RC, STM32L162VC                           |                 |
| stm32l162xd   | STM32L162QD, STM32L156RD, STM32L162VD, STM32L162ZD |                 |
| stm32l162xe   | STM32L162QE, STM32L156RE, STM32L162VE, STM32L162ZE |                 |
| stm32l052x6   | STM32L052K6, STM32L052T6, STM32L052C6, STM32L052R6 |                 |
| stm32l052x8   | STM32L052K8, STM32L052T8, STM32L052C8, STM32L052R8 | tested, default |
| stm32l053x6   | STM32L053C6, STM32L053R6                           |                 |
| stm32l053x8   | STM32L053C8, STM32L053R8                           |                 |
| stm32l062x8   | STM32L062K8                                        |                 |
| stm32l063x8   | STM32L063C8, STM32L063R8                           |                 |
| stm32l072v8   | STM32L072V8                                        |                 |
| stm32l072xb   | STM32L072KB, STM32L072CB, STM32L072RB, STM32L072VB | tested          |
| stm32l072xz   | STM32L072KZ, STM32L072CZ, STM32L072RZ, STM32L072VZ |                 |
| stm32l073v8   | STM32L073V8                                        |                 |
| stm32l073xb   | STM32L073CB, STM32L073RB, STM32L073VB              |                 |
| stm32l073xz   | STM32L073CZ, STM32L073RZ, STM32L073VZ              |                 |
| stm32l476xc   | STM32L476RC, STM32L476VC                           |                 |
| stm32l476xe   | STM32L476RE, STM32L476JE, STM32L476ME, STM32L476VE |                 |
| stm32l476xg   | STM32L476RG, STM32L476JG, STM32L476MG, STM32L476VG | tested          |
| stm32f103x6   | STM32F103T6, STM32F103C6, STM32F103R6              |                 |
| stm32f103x8   | STM32F103T8, STM32F103C8, STM32F103R8, STM32f103V8 | tested          |
| stm32f105xb   | STM32F105RB, STM32F105VB                           | tested          |
| stm32f107xb   | STM32F107RB, STM32F107VB                           | tested          |
| stm32l433xb   | STM32L433CB, STM32L433RB                           |                 |
| stm32l433xc   | STM32L433CC, STM32L433RC, STM32L433VC              | tested          |
| stm32f070x6   | STM32F070C6                                        |                 |
| stm32f070xb   | STM32F070CB                                        | tested          |
| stm32f429xe   | STM32F429xE series (single bank mode)              |                 |
| stm32f429xg   | STM32F429xG series (single bank mode)              |                 |
| stm32f429xi   | STM32F429xI series (single and dual bank)          | tested           |
| stm32g431x6   | STM32G431x6, STM32G441x6                           |                 |
| stm32g431x8   | STM32G431x8, STM32G441x8                           |                 |
| stm32g431xb   | STM32G431xB, STM32G441xB                           | tested G431RB   |
| stm32g474xb   | STM32G471xB, STM32G473xB, STM32G474xB, STM32G483xB |                 |
| stm32g474xc   | STM32G471xC, STM32G473xC, STM32G474xC, STM32G483xC |                 |
| stm32g474xe   | STM32G471xE, STM32G473xE, STM32G474xE, STM32G483xE | tested G747RE   |
| stm32f303xe   | STM32F303xE                                        | tested          |
| stm32f373xc   | STM32F373xC                                        | tested          |

#### Adjusting user firmware
+ Check bootloader's linker map for the ````__app_start```` address. This is the new ROM origin for the user firmware (ISR vectors).
+ Adjust your linker script to set new ROM origin and ROM length.

#### Utilizing usbd core and usbd driver from bootloader in the user firmware
+ Check bootloader's linker map for the ````usbd_poll```` entry point and usbd driver (````usbd_devfs````, ````usbd_otgfs````, e.t.c. depends used MCU). It's located just after the ```.isr_vector``` section.
+ Add address for usbd_driver structure to your linker script. For example ````usbd_drv    = 0x08000040;````
+ Add address for usbd_poll entry point to your linker script. For example ````usbd_poll   = 0x08000074;````
+ Add ````extern struct usbd_driver usbd_drv;```` driver declaration to your code.
+ Include at least "usbd_core.h" and "usb_std.h" to your code.

Now you can use the usbd core and driver from the bootloader in your application. Don't forget to set GPIO and RCC for USB according to MCU requirements.

#### Activating bootloader
+ Write DFU_BOOTKEY at DFU_BOOTKEY_ADDR (RAM top by default) and make a software reset.
+ Assert DFU_BOOTSTRAP_PIN on DFU_BOOTSTRAP_PORT on startup (optional).
+ Make a double reset during the DFU_DBLRESET_MS period (optional).

#### Encrypting user firmware
We provide a utility for encryption and decryption of firmware images. At this moment, only raw binary files are supported.

To encrypt:
````
fwcrypt -e -i infile.bin -o outfile.bin
````
To decrypt:
````
fwcrypt -d -i infile.bin -o outfile.bin
````
