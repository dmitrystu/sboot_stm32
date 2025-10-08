TOOLSET    ?= arm-none-eabi-
OUTDIR     ?= build
FWNAME     ?= firmware
SWNAME     ?= fwcrypt
FWTOOLS    ?= $(TOOLSET)
CMSIS      ?= CMSIS
CMSISDEV   ?= $(CMSIS)/Device
LOADER_OUT ?= $(OUTDIR)/$(FWNAME).elf
SCRAMBLER_OUT ?= $(OUTDIR)/$(SWNAME)$(EXT)
TEST_OUT ?= $(OUTDIR)/cipher_test$(EXT)
THISPATH := $(dir $(lastword $(MAKEFILE_LIST)))
LIBUSB_PATH ?= $(THISPATH)usb/

STPROG_CLI ?= ~/STMicroelectronics/STM32Cube/STM32CubeProgrammer/bin/STM32_Programmer_CLI

ifeq ($(OS),Windows_NT)
EXT = .exe
else
EXT =
endif




ifeq ($(findstring cmd,$(SHELL)),cmd)
FixPath = $(subst /,\,$1)
RM = del /Q
MKDIR = mkdir
else ifeq ($(findstring powershell,$(SHELL)),powershell)
FixPath = $1
RM = Remove-Item -Force
MKDIR = New-Item -Force -ItemType Directory
else
FixPath = $1
RM = rm -rf
MKDIR = mkdir
endif

#default CPU target is STM32L052x8
FWCPU	   ?= -mcpu=cortex-m0plus -mfloat-abi=soft
FWDEFS     ?= STM32L0 STM32L052xx
FWSTARTUP  ?= mcu/stm32l0xx.S
LDPARAMS   ?= ROMLEN=64K RAMLEN=8K

#sources
CRYPT_SRC   = src/arc4.c src/chacha.c src/gost.c src/raiden.c src/rc5.c src/speck.c
CRYPT_SRC  += src/xtea.c src/xtea1.c src/blowfish.c src/rtea.c src/rc6.c src/rijndael.c
CRYPT_SRC  += src/magma.c
CRYPT_SRC  += src/checksum.c src/crypto.c

FW_SRC = $(addprefix $(THISPATH),$(CRYPT_SRC) $(FWSTARTUP))
FW_SRC += $(addprefix $(THISPATH), src/bootloader.c src/descriptors.c src/rc5a.S src/chacha_a.S src/rc6a.S)
FW_SRC += $(wildcard $(LIBUSB_PATH)src/*.c) $(wildcard $(LIBUSB_PATH)src/*.S)
SW_SRC = $(addprefix $(THISPATH),$(CRYPT_SRC) src/encrypter.c)
TS_SRC = $(addprefix $(THISPATH),$(filter-out src/crypto.c, $(CRYPT_SRC)) src/ctest.c)

#folders
FWODIR = $(dir $(LOADER_OUT))
SWODIR = $(dir $(SCRAMBLER_OUT))

#includes
CMSISINC    = $(CMSISDEV)/ST $(CMSIS)/CMSIS/Include $(CMSIS)/CMSIS/Core/Include
FWINCS = . $(addprefix $(THISPATH),. inc) $(CMSISINC) $(LIBUSB_PATH)inc
SWINCS = . $(addprefix $(THISPATH),. inc)

#compiler flags
COMPILER_MACROS := $(shell gcc -dM -E - </dev/null)
ifneq (,$(findstring __clang__,$(COMPILER_MACROS)))
SWCFLAGS = -Os -std=c11 -fdata-sections -ffunction-sections -Werror -Wl,-dead_strip
else ifneq (,$(findstring __GNUC__,$(COMPILER_MACROS)))
SWCFLAGS = -Os -std=c11 -fdata-sections -ffunction-sections -Werror -Wl,--gc-sections -s
endif


FWCFLAGS = -Os -flto -ffunction-sections -fdata-sections

#linker flags
LDSCRIPT = $(LOADER_OUT:.elf=.ld)
LDMAP = $(LOADER_OUT:.elf=.map)
LDFLAGS = -specs=nano.specs -nostartfiles -Wl,--gc-sections -Wl,-Map=$(LDMAP) -Wl,--script=$(LDSCRIPT)

#passing DFU related variables
USERDEFS = $(foreach v,$(filter DFU_%,$(.VARIABLES)),$(v)=$($(v)) )

#preconfigured targets
FWTARGETS  := bootloader
FWTARGETS  += stm32l100x6a stm32l100x8a stm32l100xba stm32l100xc
FWTARGETS  += stm32l151x6a stm32l151x8a stm32l151xba stm32l151xc stm32l151xd stm32l151xe
FWTARGETS  += stm32l152x6a stm32l152x8a stm32l152xba stm32l152xc stm32l152xd stm32l152xe
FWTARGETS  += stm32l152xc stm32l162xc stm32l162xd stm32l162xe
FWTARGETS  += stm32l052x6 stm32l052x8 stm32l053x6 stm32l053x8
FWTARGETS  += stm32l062x8 stm32l063x8
FWTARGETS  += stm32l072x8 stm32l072xb stm32l072xc
FWTARGETS  += stm32l073x8 stm32l073xb stm32l073xc
FWTARGETS  += stm32l476xc stm32l476xe stm32l476xg
FWTARGETS  += stm32f103x4 stm32f103x6 stm32f103x8 stm32f103xb stm32f103xc
FWTARGETS  += stm32f303xb stm32f303xc stm32f303xd stm32f303xe
FWTARGETS  += stm32f401xe stm32f411xe stm32f429xe stm32f429xg stm32f429xi stm32f429xi_hs
FWTARGETS  += stm32f105xb stm32f107xb
FWTARGETS  += stm32l433xb stm32l433xc
FWTARGETS  += stm32f070x6 stm32f070xb stm32f072x8
FWTARGETS  += stm32g431x6 stm32g431x8 stm32g431xb
FWTARGETS  += stm32g474xb stm32g474xc stm32g474xe
FWTARGETS  += stm32f446xc stm32f446xc_hs stm32f446xe stm32f446xe_hs
FWTARGETS  += stm32f405xg stm32f405xg_hs

all: bootloader crypter

program_stcube: $(LOADER_OUT:%.elf=%.hex)
	$(STPROG_CLI) -c port=SWD reset=HWrst -d $< -hardRst

program: $(LOADER_OUT:%.elf=%.hex)
	st-flash --reset --format ihex write $<

crypter: $(SCRAMBLER_OUT)
scrambler: $(SCRAMBLER_OUT)

testsuite: $(TEST_OUT)
	@echo Running tests
	@$(TEST_OUT)

$(FWTARGETS): $(LOADER_OUT)

prerequisites: $(CMSISDEV)/ST $(LIBUSB_PATH)/.git

%/.git: %
	@git submodule update --init $<

fwclean:
	$(RM) $(LDSCRIPT) $(LDMAP) $(LOADER_OUT)

swclean:
	$(RM) $(SCRAMBLER_OUT) $(TEST_OUT)

clean: fwclean swclean

FORCE:

#external dependency
$(LIBUSB_PATH):
	@git clone --depth 1 https://github.com/dmitrystu/libusb_stm32.git $@

$(CMSISDEV)/ST: $(CMSIS)
	@git clone --recurse-submodules --depth 1 https://github.com/dmitrystu/stm32h.git $@

$(CMSIS):
	@git clone --depth 1 https://github.com/ARM-software/CMSIS_5.git $@

#target folders handling
$(sort $(FWODIR) $(SWODIR)):
	@$(MKDIR) $(@D)

#build scripts
%.hex: %.elf
	@echo Building HEX $@
	@$(FWTOOLS)objcopy -O ihex $< $@

%.bin: %.elf
	@echo Building binary $@
	@$(FWTOOLS)objcopy -O binary $< $@

%.srec: %.elf
	@echo Building Motorolla Srec $@
	@$(FWTOOLS)objcopy -O srec $< $@

.SECONDEXPANSION:
$(LDSCRIPT): $(FWODIR)
	@$(MAKE) -f $(THISPATH)ldscript.mk $(LDPARAMS) OUTFILE=$@

$(LOADER_OUT): $$(FW_SRC) $(LDSCRIPT) FORCE | $(LIBUSB_PATH) $(CMSISDEV)/ST $(FWODIR)
	@echo Building bootloader $@
	@$(FWTOOLS)gcc $(FWCFLAGS) $(FWCPU) $(addprefix -I,$(FWINCS)) $(addprefix -D,$(USERDEFS) $(FWDEFS)) $(FW_SRC) $(LDFLAGS) -o $@
	@$(FWTOOLS)size $@

$(SCRAMBLER_OUT): $(SW_SRC) FORCE | $(SWODIR)
	@echo Building scrambler $@
	@gcc $(SWCFLAGS) $(addprefix -I,$(SWINCS)) $(addprefix -D,$(USERDEFS)) $(SW_SRC) -o $@

$(TEST_OUT): $(TS_SRC) | $(SWODIR)
	@echo creating cipher testsuite
	@gcc $(SWCFLAGS) $(addprefix -I,$(SWINCS)) $(TS_SRC) -o $@

#predefines
stm32l052x6 : LDPARAMS = ROMLEN=32K RAMLEN=8K
stm32l052x6 : FWDEFS = STM32L0 STM32L052xx USBD_ASM_DRIVER
stm32l052x6 : FWCPU = -mcpu=cortex-m0plus
stm32l052x6 : FWSTARTUP = mcu/stm32l0xx.S

stm32l052x8 : LDPARAMS = ROMLEN=64K RAMLEN=8K
stm32l052x8 : FWDEFS = STM32L0 STM32L052xx USBD_ASM_DRIVER
stm32l052x8 : FWCPU = -mcpu=cortex-m0plus
stm32l052x8 : FWSTARTUP = mcu/stm32l0xx.S

stm32l053x6 : LDPARAMS = ROMLEN=32K RAMLEN=8K
stm32l053x6 : FWDEFS = STM32L0 STM32L053xx
stm32l053x6 : FWCPU = -mcpu=cortex-m0plus
stm32l053x6 : FWSTARTUP = mcu/stm32l0xx.S

stm32l053x8 : LDPARAMS = ROMLEN=64K RAMLEN=8K
stm32l053x8 : FWDEFS = STM32L0 STM32L053xx
stm32l053x8 : FWCPU = -mcpu=cortex-m0plus
stm32l053x8 : FWSTARTUP = mcu/stm32l0xx.S

stm32l062x8 : LDPARAMS = ROMLEN=64K RAMLEN=8K
stm32l062x8 : FWDEFS = STM32L0 STM32L062xx
stm32l062x8 : FWCPU = -mcpu=cortex-m0plus
stm32l062x8 : FWSTARTUP = mcu/stm32l0xx.S

stm32l063x8 : LDPARAMS = ROMLEN=64K RAMLEN=8K
stm32l063x8 : FWDEFS = STM32L0 STM32L063xx
stm32l063x8 : FWCPU = -mcpu=cortex-m0plus
stm32l063x8 : FWSTARTUP = mcu/stm32l0xx.S

stm32l072x8 : LDPARAMS = ROMLEN=64K RAMLEN=20K
stm32l072x8 : FWDEFS = STM32L0 STM32L072xx
stm32l072x8 : FWCPU = -mcpu=cortex-m0plus
stm32l072x8 : FWSTARTUP = mcu/stm32l0xx.S

stm32l072xb : LDPARAMS = ROMLEN=128K RAMLEN=20K
stm32l072xb : FWDEFS = STM32L0 STM32L072xx
stm32l072xb : FWCPU = -mcpu=cortex-m0plus
stm32l072xb : FWSTARTUP = mcu/stm32l0xx.S

stm32l072xc : LDPARAMS = ROMLEN=192K RAMLEN=20K
stm32l072xc : FWDEFS = STM32L0 STM32L072xx
stm32l072xc : FWCPU = -mcpu=cortex-m0plus
stm32l072xc : FWSTARTUP = mcu/stm32l0xx.S

stm32l073x8 : LDPARAMS = ROMLEN=64K RAMLEN=20K
stm32l073x8 : FWDEFS = STM32L0 STM32L073xx
stm32l073x8 : FWCPU = -mcpu=cortex-m0plus
stm32l073x8 : FWSTARTUP = mcu/stm32l0xx.S

stm32l073xb : LDPARAMS = ROMLEN=128K RAMLEN=20K
stm32l073xb : FWDEFS = STM32L0 STM32L073xx
stm32l073xb : FWCPU = -mcpu=cortex-m0plus
stm32l073xb : FWSTARTUP = mcu/stm32l0xx.S

stm32l073xc : LDPARAMS = ROMLEN=192K RAMLEN=20K
stm32l073xc : FWDEFS = STM32L0 STM32L073xx
stm32l073xc : FWCPU = -mcpu=cortex-m0plus
stm32l073xc : FWSTARTUP = mcu/stm32l0xx.S

stm32l100x6a: LDPARAMS = ROMLEN=32K RAMLEN=4K
stm32l100x6a: FWDEFS = STM32L1 STM32L100xBA USBD_ASM_DRIVER
stm32l100x6a: FWCPU = -mcpu=cortex-m3
stm32l100x6a: FWSTARTUP = mcu/stm32l1xx.S

stm32l100x8a: LDPARAMS = ROMLEN=64K RAMLEN=8K
stm32l100x8a: FWCPU = -mcpu=cortex-m3
stm32l100x8a: FWDEFS = STM32L1 STM32L100xBA USBD_ASM_DRIVER
stm32l100x8a: FWSTARTUP =mcu/stm32l1xx.S

stm32l100xba: LDPARAMS = ROMLEN=128K RAMLEN=16K
stm32l100xba: FWCPU = -mcpu=cortex-m3
stm32l100xba: FWSTARTUP := mcu/stm32l1xx.S
stm32l100xba: FWDEFS = STM32L1 STM32L100xBA USBD_ASM_DRIVER

stm32l100xc : LDPARAMS = ROMLEN=256K RAMLEN=16K
stm32l100xc : FWDEFS = STM32L1 STM32L100xC USBD_ASM_DRIVER
stm32l100xc : FWCPU = -mcpu=cortex-m3
stm32l100xc : FWSTARTUP = mcu/stm32l1xx.S

stm32l151x6a : LDPARAMS = ROMLEN=32K RAMLEN=16K
stm32l151x6a : FWDEFS = STM32L1 STM32L151xBA
stm32l151x6a : FWCPU = -mcpu=cortex-m3
stm32l151x6a : FWSTARTUP = mcu/stm32l1xx.S

stm32l151x8a : LDPARAMS = ROMLEN=64K RAMLEN=32K
stm32l151x8a : FWDEFS = STM32L1 STM32L151xBA
stm32l151x8a : FWCPU = -mcpu=cortex-m3
stm32l151x8a : FWSTARTUP = mcu/stm32l1xx.S

stm32l151xba : LDPARAMS = ROMLEN=128K RAMLEN=32K
stm32l151xba : FWDEFS = STM32L1 STM32L151xBA
stm32l151xba : FWCPU = -mcpu=cortex-m3
stm32l151xba : FWSTARTUP = mcu/stm32l1xx.S

stm32l151xc : LDPARAMS = ROMLEN=256K RAMLEN=32K
stm32l151xc : FWDEFS = STM32L1 STM32L151xC
stm32l151xc : FWCPU = -mcpu=cortex-m3
stm32l151xc : FWSTARTUP = mcu/stm32l1xx.S

stm32l151xd : LDPARAMS = ROMLEN=384K RAMLEN=48K
stm32l151xd : FWDEFS = STM32L1 STM32L151xD
stm32l151xd : FWSTARTUP = mcu/stm32l1xx.S
stm32l151xd : FWCPU = -mcpu=cortex-m3

stm32l151xe : LDPARAMS = ROMLEN=512K RAMLEN=80K
stm32l151xe : FWDEFS = STM32L1 STM32L151xE
stm32l151xe : FWCPU = -mcpu=cortex-m3
stm32l151xe : FWSTARTUP = mcu/stm32l1xx.S

stm32l152x6a : LDPARAMS = ROMLEN=32K RAMLEN=16K
stm32l152x6a : FWDEFS = STM32L1 STM32L152xBA
stm32l152x6a : FWCPU = -mcpu=cortex-m3
stm32l152x6a : FWSTARTUP = mcu/stm32l1xx.S

stm32l152x8a : LDPARAMS = ROMLEN=64K RAMLEN=32K
stm32l152x8a : FWDEFS = STM32L1 STM32L152xBA
stm32l152x8a : FWCPU = -mcpu=cortex-m3
stm32l152x8a : FWSTARTUP = mcu/stm32l1xx.S

stm32l152xba : LDPARAMS = ROMLEN=128K RAMLEN=32K
stm32l152xba : FWDEFS = STM32L1 STM32L152xBA
stm32l152xba : FWCPU = -mcpu=cortex-m3
stm32l152xba : FWSTARTUP = mcu/stm32l1xx.S

stm32l152xc : LDPARAMS = ROMLEN=256K RAMLEN=32K
stm32l152xc : FWDEFS = STM32L1 STM32L152xC
stm32l152xc : FWCPU = -mcpu=cortex-m3
stm32l152xc : FWSTARTUP = mcu/stm32l1xx.S

stm32l152xd : LDPARAMS = ROMLEN=384K RAMLEN=48K
stm32l152xd : FWDEFS = STM32L1 STM32L152xD
stm32l152xd : FWCPU = -mcpu=cortex-m3
stm32l152xd : FWSTARTUP = mcu/stm32l1xx.S

stm32l152xe : LDPARAMS = ROMLEN=512K RAMLEN=80K
stm32l152xe : FWDEFS = STM32L1 STM32L152xE
stm32l152xe : FWCPU = -mcpu=cortex-m3
stm32l152xe : FWSTARTUP = mcu/stm32l1xx.S

stm32l162xc : LDPARAMS = ROMLEN=256K RAMLEN=32K
stm32l162xc : FWDEFS = STM32L1 STM32L162xC
stm32l162xc : FWCPU = -mcpu=cortex-m3
stm32l162xc : FWSTARTUP = mcu/stm32l1xx.S

stm32l162xd : LDPARAMS = ROMLEN=384K RAMLEN=48K
stm32l162xd : FWDEFS = STM32L1 STM32L162xD
stm32l162xd : FWCPU = -mcpu=cortex-m3
stm32l162xd : FWSTARTUP = mcu/stm32l1xx.S

stm32l162xe : LDPARAMS = ROMLEN=512K RAMLEN=80K
stm32l162xe : FWDEFS = STM32L1 STM32L162xE
stm32l162xe : FWCPU = -mcpu=cortex-m3
stm32l162xe : FWSTARTUP = mcu/stm32l1xx.S

stm32l433xb : LDPARAMS = ROMLEN=128K RAMLEN=48K
stm32l433xb : FWDEFS = STM32L4 STM32L433xx USBD_ASM_DRIVER
stm32l433xb : FWCPU = -mcpu=cortex-m4
stm32l433xb : FWSTARTUP = mcu/stm32l4xx.S

stm32l433xc : LDPARAMS = ROMLEN=256K RAMLEN=48K
stm32l433xc : FWDEFS = STM32L4 STM32L433xx USBD_ASM_DRIVER
stm32l433xc : FWCPU = -mcpu=cortex-m4
stm32l433xc : FWSTARTUP = mcu/stm32l4xx.S

stm32l476xc : LDPARAMS = ROMLEN=256K RAMLEN=96K
stm32l476xc : FWDEFS = STM32L4 STM32L476xx
stm32l476xc : FWCPU = -mcpu=cortex-m4
stm32l476xc : FWSTARTUP = mcu/stm32l4xx.S

stm32l476xe : LDPARAMS = ROMLEN=512K RAMLEN=96K
stm32l476xe : FWDEFS = STM32L4 STM32L476xx
stm32l476xe : FWCPU = -mcpu=cortex-m4
stm32l476xe : FWSTARTUP = mcu/stm32l4xx.S

stm32l476xg : LDPARAMS = ROMLEN=1024K RAMLEN=96K
stm32l476xg : FWDEFS = STM32L4 STM32L476xx
stm32l476xg : FWCPU = -mcpu=cortex-m4
stm32l476xg : FWSTARTUP = mcu/stm32l4xx.S

stm32f070x6 : LDPARAMS = ROMLEN=32K RAMLEN=6K
stm32f070x6 : FWDEFS = STM32F0 STM32F070x6 USBD_ASM_DRIVER
stm32f070x6 : FWCPU = -mcpu=cortex-m0
stm32f070x6 : FWSTARTUP = mcu/stm32f0xx.S

stm32f070xb : LDPARAMS = ROMLEN=128K RAMLEN=16K
stm32f070xb : FWDEFS = STM32F0 STM32F070xB USBD_ASM_DRIVER
stm32f070xb : FWCPU = -mcpu=cortex-m0
stm32f070xb : FWSTARTUP = mcu/stm32f0xx.S

stm32f072x8 : LDPARAMS = ROMLEN=64K RAMLEN=16K APPALIGN=0x1000
stm32f072x8 : FWDEFS = STM32F0 STM32F072xB USBD_ASM_DRIVER
stm32f072x8 : FWCPU = -mcpu=cortex-m0
stm32f072x8 : FWSTARTUP = mcu/stm32f0xx.S

stm32f103x4 : LDPARAMS = ROMLEN=16K RAMLEN=10K
stm32f103x4 : FWDEFS = STM32F1 STM32F103x6 USBD_ASM_DRIVER
stm32f103x4 : FWCPU = -mcpu=cortex-m3
stm32f103x4 : FWSTARTUP = mcu/stm32f103.S

stm32f103x6 : LDPARAMS = ROMLEN=32K RAMLEN=10K
stm32f103x6 : FWDEFS = STM32F1 STM32F103x6 USBD_ASM_DRIVER
stm32f103x6 : FWCPU = -mcpu=cortex-m3
stm32f103x6 : FWSTARTUP = mcu/stm32f103.S

stm32f103x8 : LDPARAMS = ROMLEN=64K RAMLEN=20K
stm32f103x8 : FWDEFS = STM32F1 STM32F103x6 USBD_ASM_DRIVER
stm32f103x8 : FWCPU = -mcpu=cortex-m3
stm32f103x8 : FWSTARTUP = mcu/stm32f103.S

stm32f103xb : LDPARAMS = ROMLEN=128K RAMLEN=20K
stm32f103xb : FWDEFS = STM32F1 STM32F103x6 USBD_ASM_DRIVER
stm32f103xb : FWCPU = -mcpu=cortex-m3
stm32f103xb : FWSTARTUP = mcu/stm32f103.S

stm32f103xc : LDPARAMS = ROMLEN=256K RAMLEN=48K
stm32f103xc : FWDEFS = STM32F1 STM32F103xE USBD_ASM_DRIVER
stm32f103xc : FWCPU = -mcpu=cortex-m3
stm32f103xc : FWSTARTUP = mcu/stm32f103.S

stm32f105xb : LDPARAMS = ROMLEN=128K RAMLEN=20K
stm32f105xb : FWDEFS = STM32F1 STM32F105xC USBD_VBUS_DETECT
stm32f105xb : FWCPU = -mcpu=cortex-m3
stm32f105xb : FWSTARTUP = 'mcu/stm32f105.S

stm32f107xb : LDPARAMS = ROMLEN=128K RAMLEN=20K
stm32f107xb : FWDEFS = STM32F1 STM32F107xC HSE_25MHZ USBD_VBUS_DETECT
stm32f107xb : FWCPU = -mcpu=cortex-m3
stm32f107xb : FWSTARTUP = mcu/stm32f105.S

stm32f303xb : LDPARAMS = ROMLEN=128K RAMLEN=40K
stm32f303xb : FWDEFS= STM32F3 STM32F303xC USBD_ASM_DRIVER
stm32f303xb : FWCPU = -mcpu=cortex-m4
stm32f303xb : FWSTARTUP = mcu/stm32f303.S

stm32f303xc : LDPARAMS = ROMLEN=256K RAMLEN=40K
stm32f303xc : FWDEFS= STM32F3 STM32F303xC USBD_ASM_DRIVER
stm32f303xc : FWCPU = -mcpu=cortex-m4
stm32f303xc : FWSTARTUP = mcu/stm32f303.S

stm32f303xd : LDPARAMS = ROMLEN=384K RAMLEN=64K
stm32f303xd : FWDEFS= STM32F3 STM32F303xE USBD_ASM_DRIVER
stm32f303xd : FWCPU = -mcpu=cortex-m4
stm32f303xd : FWSTARTUP = mcu/stm32f303.S

stm32f303xe : LDPARAMS = ROMLEN=512K RAMLEN=64K
stm32f303xe : FWDEFS= STM32F3 STM32F303xE USBD_ASM_DRIVER
stm32f303xe : FWCPU = -mcpu=cortex-m4
stm32f303xe : FWSTARTUP = mcu/stm32f303.S

stm32f373xc : LDPARAMS = ROMLEN=256K RAMLEN=32K
stm32f373xc : FWDEFS= STM32F3 STM32F373xC USBD_ASM_DRIVER
stm32f373xc : FWCPU = -mcpu=cortex-m4
stm32f373xc : FWSTARTUP = mcu/stm32f303.S

stm32f401xe : LDPARAMS = ROMLEN=512K RAMLEN=96K APPALIGN=0x4000
stm32f401xe : FWDEFS = STM32F4 STM32F401xE
stm32f401xe : FWCPU = -mcpu=cortex-m4
stm32f401xe : FWSTARTUP = mcu/stm32f4xx.S

stm32f405xg : LDPARAMS = ROMLEN=1024K RAMLEN=128K APPALIGN=0x4000
stm32f405xg : FWDEFS = STM32F4 STM32F405xx
stm32f405xg : FWCPU = -mcpu=cortex-m4
stm32f405xg : FWSTARTUP = mcu/stm32f4xx.S

stm32f405xg_hs : LDPARAMS = ROMLEN=1024K RAMLEN=128K APPALIGN=0x4000
stm32f405xg_hs : FWDEFS = STM32F4 STM32F405xx USBD_PRIMARY_OTGHS
stm32f405xg_hs : FWCPU = -mcpu=cortex-m4
stm32f405xg_hs : FWSTARTUP = mcu/stm32f4xx.S

stm32f411xe : LDPARAMS = ROMLEN=512K RAMLEN=128K APPALIGN=0x4000
stm32f411xe : FWDEFS = STM32F4 STM32F411xE
stm32f411xe : FWCPU = -mcpu=cortex-m4
stm32f411xe : FWSTARTUP = mcu/stm32f4xx.S

stm32f429xe : LDPARAMS = ROMLEN=512K RAMLEN=192K APPALIGN=0x4000
stm32f429xe : FWDEFS = STM32F4 STM32F429xx
stm32f429xe : FWCPU = -mcpu=cortex-m4
stm32f429xe : FWSTARTUP = mcu/stm32f4xx.S

stm32f429xg : LDPARAMS = ROMLEN=1024K RAMLEN=192K APPALIGN=0x4000
stm32f429xg : FWDEFS = STM32F4 STM32F429xx
stm32f429xg : FWCPU = -mcpu=cortex-m4
stm32f429xg : FWSTARTUP = mcu/stm32f4xx.S

stm32f429xi : LDPARAMS = ROMLEN=2048K RAMLEN=192K APPALIGN=0x4000
stm32f429xi : FWDEFS = STM32F4 STM32F429xx
stm32f429xi : FWCPU = -mcpu=cortex-m4
stm32f429xi : FWSTARTUP = mcu/stm32f4xx.S

stm32f429xi_hs : LDPARAMS = ROMLEN=2048K RAMLEN=192K APPALIGN=0x4000
stm32f429xi_hs : FWDEFS = STM32F4 STM32F429xx USBD_PRIMARY_OTGHS
stm32f429xi_hs : FWCPU = -mcpu=cortex-m4
stm32f429xi_hs : FWSTARTUP = mcu/stm32f4xx.S

stm32f446xc : LDPARAMS = ROMLEN=256K RAMLEN=128K APPALIGN=0x4000
stm32f446xc : FWDEFS = STM32F4 STM32F446xx
stm32f446xc : FWCPU = -mcpu=cortex-m4
stm32f446xc : FWSTARTUP = mcu/stm32f4xx.S

stm32f446xc_hs : LDPARAMS = ROMLEN=256K RAMLEN=128K APPALIGN=0x4000
stm32f446xc_hs : FWDEFS = STM32F4 STM32F446xx USBD_PRIMARY_OTGHS
stm32f446xc_hs : FWCPU = -mcpu=cortex-m4
stm32f446xc_hs : FWSTARTUP = mcu/stm32f4xx.S

stm32f446xe : LDPARAMS = ROMLEN=512K RAMLEN=128K APPALIGN=0x4000
stm32f446xe : FWDEFS = STM32F4 STM32F446xx
stm32f446xe : FWCPU = -mcpu=cortex-m4
stm32f446xe : FWSTARTUP = mcu/stm32f4xx.S

stm32f446xe_hs : LDPARAMS = ROMLEN=512K RAMLEN=128K APPALIGN=0x4000
stm32f446xe_hs : FWDEFS = STM32F4 STM32F446xx USBD_PRIMARY_OTGHS
stm32f446xe_hs : FWCPU = -mcpu=cortex-m4
stm32f446xe_hs : FWSTARTUP = mcu/stm32f4xx.S

stm32g431x6: LDPARAMS = ROMLEN=32K RAMLEN=22K
stm32g431x6: FWDEFS = STM32G4 STM32G431xx USBD_ASM_DRIVER
stm32g431x6: FWCPU = -mcpu=cortex-m4
stm32g431x6: FWSTARTUP = mcu/stm32g4xx.S

stm32g431x8: LDPARAMS = ROMLEN=64K RAMLEN=22K
stm32g431x8: FWDEFS = STM32G4 STM32G431xx USBD_ASM_DRIVER
stm32g431x8: FWCPU = -mcpu=cortex-m4
stm32g431x8: FWSTARTUP = mcu/stm32g4xx.S

stm32g431xb: LDPARAMS = ROMLEN=128K RAMLEN=22K
stm32g431xb: FWDEFS = STM32G4 STM32G431xx USBD_ASM_DRIVER
stm32g431xb: FWCPU = -mcpu=cortex-m4
stm32g431xb: FWSTARTUP = mcu/stm32g4xx.S

stm32g474xb: LDPARAMS = ROMLEN=128K RAMLEN=96K APPALIGN=0x1000
stm32g474xb: FWDEFS = STM32G4 STM32G474xx USBD_ASM_DRIVER
stm32g474xb: FWCPU = -mcpu=cortex-m4
stm32g474xb: FWSTARTUP = mcu/stm32g4xx.S

stm32g474xc: LDPARAMS = ROMLEN=256K RAMLEN=96K APPALIGN=0x1000
stm32g474xc: FWDEFS = STM32G4 STM32G474xx USBD_ASM_DRIVER
stm32g474xc: FWCPU = -mcpu=cortex-m4
stm32g474xc: FWSTARTUP = mcu/stm32g4xx.S

stm32g474xe: LDPARAMS = ROMLEN=512K RAMLEN=96K APPALIGN=0x1000
stm32g474xe: FWDEFS = STM32G4 STM32G474xx USBD_ASM_DRIVER
stm32g474xe: FWCPU = -mcpu=cortex-m4 -mthumb
stm32g474xe: FWSTARTUP = mcu/stm32g4xx.S

.PHONY: swclean fwclean clean bootloader scrambler crypter all testsuite program program_stcube $(FWTARGETS) FORCE

.INTERMEDIATE: $(LDSCRIPT)