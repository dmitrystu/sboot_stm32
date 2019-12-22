TOOLSET    ?= arm-none-eabi-
OUTDIR     ?= build
FWNAME     ?= firmware
SWNAME     ?= fwcrypt
FWTOOLS    ?= $(TOOLSET)
CMSIS      ?= $(abspath ../CMSIS)
CMSISDEV   ?= $(CMSIS)/Device

STPROG_CLI ?= ~/STMicroelectronics/STM32Cube/STM32CubeProgrammer/bin/STM32_Programmer_CLI

ifeq ($(OS),Windows_NT)
	RM = del /Q
	FixPath = $(subst /,\, $1)
	SWTOOLS ?= mingw32-
	SWFLAGS ?=
else
	RM = rm -f
	FixPath = $1
	SWTOOLS ?=
	SWFLAGS ?=
endif

#default CPU target is STM32L052x8
FWCPU	   ?= -mcpu=cortex-m0plus -mfloat-abi=soft
FWDEFS     ?= STM32L0 STM32L052xx
FWSTARTUP  ?= mcu/stm32l0xx.S
LDPARAMS   ?= ROMLEN=64K RAMLEN=8K

#sources
CRYPT_SRC   = src/arc4.c src/chacha.c src/gost.c src/raiden.c src/rc5.c src/speck.c
CRYPT_SRC  += src/xtea.c src/blowfish.c src/rtea.c src/checksum.c
FW_SRC      = $(CRYPT_SRC) $(FWSTARTUP) src/descriptors.c src/bootloader.c src/rc5a.S src/chacha_a.S
SW_SRC      = $(CRYPT_SRC) src/encrypter.c

#folders
FWODIR    = $(OUTDIR)/objfw
SWODIR    = $(OUTDIR)/objsw
SRCPATH   = $(sort $(dir $(FW_SRC)))
vpath %.c $(SRCPATH)
vpath %.S $(SRCPATH)

#includes
CMSISINC    = $(CMSISDEV)/ST $(CMSIS)/CMSIS/Include $(CMSIS)/CMSIS/Core/Include
FWINCS      = $(CMSISINC) inc $(addsuffix /inc, $(MODULES)) .
SWINCS      = inc .

#objects
FWOBJ     = $(addprefix $(FWODIR)/, $(addsuffix .o, $(notdir $(basename $(FW_SRC)))))
SWOBJ     = $(addprefix $(SWODIR)/, $(addsuffix .o, $(notdir $(basename $(SW_SRC)))))

#modules
MODULES     = usb
MLIBS       = $(addprefix $(FWODIR)/lib, $(addsuffix .a, $(MODULES)))
MDEFS       = USBD_SOF_DISABLED

#compiler flags
FWCFLAGS    = -mthumb -Os -Wall -std=gnu99 -fdata-sections -ffunction-sections
FWXFLAGS    = -flto

#linker flags
FWLDFLAGS   = -specs=nano.specs -nostartfiles -Wl,--gc-sections -Wl,-Map=$(OUTDIR)/$(FWNAME).map
SWLDFLAGS   = -libstd
LDSCRIPT    = $(FWODIR)/script.ld


all: bootloader crypter

program_stcube: $(OUTDIR)/$(FWNAME).hex
	$(STPROG_CLI) -c port=SWD reset=HWrst -d $< -hardRst

program: $(OUTDIR)/$(FWNAME).hex
	st-flash --reset --format ihex write $(OUTDIR)/$(FWNAME).hex

crypter: $(SWOBJ)
	@echo creating crypter
	@$(SWTOOLS)gcc $(SWCFLAGS) $(SWOBJ) -o $(OUTDIR)/$(SWNAME)

bootloader: $(OUTDIR)/$(FWNAME).hex $(OUTDIR)/$(FWNAME).bin

$(OUTDIR)/$(FWNAME).hex: $(OUTDIR)/$(FWNAME).elf
	@echo creating $@
	@$(FWTOOLS)objcopy -O ihex $< $@

$(OUTDIR)/$(FWNAME).bin: $(OUTDIR)/$(FWNAME).elf
	@echo creating $@
	@$(FWTOOLS)objcopy -O binary $< $@

.SECONDARY $(OUTDIR)/$(FWNAME).elf: $(FWOBJ) $(MLIBS) $(LDSCRIPT)
	@echo building bootloader
	@$(FWTOOLS)gcc $(FWCPU) $(FWCFLAGS) $(FWLDFLAGS) -Wl,--script=$(LDSCRIPT) $(FWOBJ) $(addprefix -l, $(MODULES)) -L$(FWODIR) -o $@

$(LDSCRIPT):
	$(MAKE) -f ldscript.mk $(LDPARAMS) OUTFILE=$(LDSCRIPT)

$(FWODIR)/lib%.a: %
	@echo building module $<
	@$(MAKE) module -C $< MODULE=$(abspath $@) DEFINES='$(FWDEFS) $(MDEFS)' CFLAGS='$(FWXFLAGS) $(FWCPU)' CMSIS='$(CMSIS)'

$(SWOBJ): | $(SWODIR)

$(FWOBJ): | $(FWODIR)

$(OUTDIR):
	@mkdir $@

$(FWODIR) $(SWODIR): | $(OUTDIR)
	@cd $(OUTDIR) && mkdir $(lastword $(subst /, ,$@)) && cd ..


$(SWODIR)/%.o: %.c
	@echo compiling $<
	@$(SWTOOLS)gcc $(SWCFLAGS) $(addprefix -D,$(SWDEFS)) $(addprefix -I,$(SWINCS)) -c $< -o $@

$(FWODIR)/%.o: %.c
	@echo compiling $<
	@$(FWTOOLS)gcc $(FWCPU) $(FWCFLAGS) $(FWXFLAGS) $(addprefix -D,$(FWDEFS)) $(addprefix -I,$(FWINCS)) -c $< -o $@

$(FWODIR)/%.o: %.S
	@echo assembling $<
	@$(FWTOOLS)gcc $(FWCFLAGS) $(addprefix -D,$(FWDEFS)) $(addprefix -I,$(FWINCS)) -c $< -o $@

fwclean: | $(FWODIR)
	@$(RM) $(call FixPath, $(FWODIR)/*.*)
	@$(RM) $(call FixPath, $(OUTDIR)/$(FWNAME)*)
	@$(RM) $(call FixPath, $(LDSCRIPT))

swclean: | $(SWODIR)
	@$(RM) $(call FixPath, $(SWODIR)/*.*)
	@$(RM) $(call FixPath, $(OUTDIR)/$(SWNAME)*)

clean: swclean fwclean

FWTARGETS   = stm32l100x6a stm32l100x8a stm32l100xba stm32l100xc
FWTARGETS  += stm32l151x6a stm32l151x8a stm32l151xba stm32l151xc stm32l151xd stm32l151xe
FWTARGETS  += stm32l152x6a stm32l152x8a stm32l152xba stm32l152xc stm32l152xd stm32l152xe
FWTARGETS  += stm32l152xc stm32l162xc stm32l162xd stm32l162xe
FWTARGETS  += stm32l052x6 stm32l052x8 stm32l053x6 stm32l053x8
FWTARGETS  += stm32l062x8 stm32l063x8
FWTARGETS  += stm32l072v8 stm32l072xb stm32l072xc
FWTARGETS  += stm32l073v8 stm32l073xb stm32l073xc
FWTARGETS  += stm32l476xc stm32l476xe stm32l476xg
FWTARGETS  += stm32f103x4 stm32f103x6 stm32f103x8 stm32f103xb
FWTARGETS  += stm32f303xb stm32f303xc stm32f303xd stm32f303xe
FWTARGETS  += stm32f429xe stm32f429xg stm32f429xi
FWTARGETS  += stm32f105xb stm32f107xb
FWTARGETS  += stm32l433xb stm32l433xc
FWTARGETS  += stm32f070x6 stm32f070xb

stm32l100x6a :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L100xBA USBD_ASM_DRIVER' \
	                           LDPARAMS='ROMLEN=32K RAMLEN=4K'

stm32l100x8a :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L100xBA USBD_ASM_DRIVER' \
	                           LDPARAMS='ROMLEN=64K RAMLEN=8K'

stm32l100xba :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L100xBA USBD_ASM_DRIVER' \
	                           LDPARAMS='ROMLEN=128K RAMLEN=16K'

stm32l100xc :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L100xC USBD_ASM_DRIVER' \
	                           LDPARAMS='ROMLEN=256K RAMLEN=16K'

stm32l151x6a :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L151xBA' \
	                           LDPARAMS='ROMLEN=32K RAMLEN=16K'

stm32l151x8a :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L151xBA'\
	                           LDPARAMS='ROMLEN=64K RAMLEN=32K'

stm32l151xba :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L151xBA' \
	                           LDPARAMS='ROMLEN=128K RAMLEN=32K'

stm32l151xc :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L151xC' \
	                           LDPARAMS='ROMLEN=256K RAMLEN=32K'

stm32l151xd :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L151xD' \
	                           LDPARAMS='ROMLEN=384K RAMLEN=48K'

stm32l151xe :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L151xE' \
	                           LDPARAMS='ROMLEN=512K RAMLEN=80K'

stm32l152x6a :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L152xBA' \
	                           LDPARAMS='ROMLEN=32K RAMLEN=16K'

stm32l152x8a :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L152xBA' \
	                           LDPARAMS='ROMLEN=64K RAMLEN=32K'

stm32l152xba :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L152xBA' \
	                           LDPARAMS='ROMLEN=128K RAMLEN=32K'

stm32l152xc :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L152xC' \
	                           LDPARAMS='ROMLEN=256K RAMLEN=32K'

stm32l152xd :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L152xD' \
	                           LDPARAMS='ROMLEN=384K RAMLEN=48K'

stm32l152xe :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L152xE' \
	                           LDPARAMS='ROMLEN=512K RAMLEN=80K'

stm32l162xc :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L162xC' \
	                           LDPARAMS='ROMLEN=256K RAMLEN=32K'

stm32l162xd :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L162xD' \
	                           LDPARAMS='ROMLEN=384K RAMLEN=48K'

stm32l162xe :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L162xE' \
	                           LDPARAMS='ROMLEN=512K RAMLEN=80K'

stm32l052x6 :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m0plus' \
	                           FWSTARTUP='mcu/stm32l0xx.S' \
	                           FWDEFS='STM32L0 STM32L052xx USBD_ASM_DRIVER' \
	                           LDPARAMS='ROMLEN=32K RAMLEN=8K'

stm32l052x8 :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m0plus' \
	                           FWSTARTUP='mcu/stm32l0xx.S' \
	                           FWDEFS='STM32L0 STM32L052xx USBD_ASM_DRIVER' \
	                           LDPARAMS='ROMLEN=64K RAMLEN=8K'

stm32l053x6 :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m0plus' \
	                           FWSTARTUP='mcu/stm32l0xx.S' \
	                           FWDEFS='STM32L0 STM32L053xx' \
	                           LDPARAMS='ROMLEN=32K RAMLEN=8K'

stm32l053x8 :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m0plus' \
	                           FWSTARTUP='mcu/stm32l0xx.S' \
	                           FWDEFS='STM32L0 STM32L053xx' \
	                           LDPARAMS='ROMLEN=64K RAMLEN=8K'

stm32l062x8 :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m0plus' \
	                           FWSTARTUP='mcu/stm32l0xx.S' \
	                           FWDEFS='STM32L0 STM32L062xx' \
	                           LDPARAMS='ROMLEN=64K RAMLEN=8K'

stm32l063x8 :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m0plus' \
	                           FWSTARTUP='mcu/stm32l0xx.S' \
	                           FWDEFS='STM32L0 STM32L063xx' \
	                           LDPARAMS='ROMLEN=64K RAMLEN=8K'

stm32l072v8 :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m0plus' \
	                           FWSTARTUP='mcu/stm32l0xx.S' \
	                           FWDEFS='STM32L0 STM32L072xx' \
	                           LDPARAMS='ROMLEN=64K RAMLEN=20K'

stm32l072xb :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m0plus' \
	                           FWSTARTUP='mcu/stm32l0xx.S' \
	                           FWDEFS='STM32L0 STM32L072xx' \
	                           LDPARAMS='ROMLEN=128K RAMLEN=20K'

stm32l072xc :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m0plus' \
	                           FWSTARTUP='mcu/stm32l0xx.S' \
	                           FWDEFS='STM32L0 STM32L072xx' \
	                           LDPARAMS='ROMLEN=192K RAMLEN=20K'

stm32l073v8 :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m0plus' \
	                           FWSTARTUP='mcu/stm32l0xx.S' \
	                           FWDEFS='STM32L0 STM32L073xx' \
	                           LDPARAMS='ROMLEN=64K RAMLEN=20K'

stm32l073xb :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m0plus' \
	                           FWSTARTUP='mcu/stm32l0xx.S' \
	                           FWDEFS='STM32L0 STM32L073xx' \
	                           LDPARAMS='ROMLEN=128K RAMLEN=20K'

stm32l073xc :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m0plus' \
	                           FWSTARTUP='mcu/stm32l0xx.S' \
	                           FWDEFS='STM32L0 STM32L073xx' \
	                           LDPARAMS='ROMLEN=192K RAMLEN=20K'

stm32l476xc :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m4' \
	                           FWSTARTUP='mcu/stm32l4xx.S' \
	                           FWDEFS='STM32L4 STM32L476xx' \
	                           LDPARAMS='ROMLEN=256K RAMLEN=96K'

stm32l476xe :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m4' \
	                           FWSTARTUP='mcu/stm32l4xx.S' \
	                           FWDEFS='STM32L4 STM32L476xx' \
	                           LDPARAMS='ROMLEN=512K RAMLEN=96K'

stm32l476xg :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m4' \
	                           FWSTARTUP='mcu/stm32l4xx.S' \
	                           FWDEFS='STM32L4 STM32L476xx' \
	                           LDPARAMS='ROMLEN=1024K RAMLEN=96K'

stm32f103x4 :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32f103.S' \
	                           FWDEFS='STM32F1 STM32F103x6 USBD_ASM_DRIVER' \
	                           LDPARAMS='ROMLEN=16K RAMLEN=10K'

stm32f103x6 :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32f103.S' \
	                           FWDEFS='STM32F1 STM32F103x6 USBD_ASM_DRIVER' \
	                           LDPARAMS='ROMLEN=32K RAMLEN=10K'

stm32f103x8 :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32f103.S' \
	                           FWDEFS='STM32F1 STM32F103x6 USBD_ASM_DRIVER' \
	                           LDPARAMS='ROMLEN=64K RAMLEN=20K'

stm32f103xb :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32f103.S' \
	                           FWDEFS='STM32F1 STM32F103x6 USBD_ASM_DRIVER' \
	                           LDPARAMS='ROMLEN=128K RAMLEN=20K'

stm32f303xb :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32f303.S' \
	                           FWDEFS='STM32F3 STM32F303xB USBD_ASM_DRIVER' \
	                           LDPARAMS='ROMLEN=128K RAMLEN=40K'

stm32f303xc :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32f303.S' \
	                           FWDEFS='STM32F3 STM32F303xB USBD_ASM_DRIVER' \
	                           LDPARAMS='ROMLEN=256K RAMLEN=40K'

stm32f303xd :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32f303.S' \
	                           FWDEFS='STM32F3 STM32F303xE USBD_ASM_DRIVER' \
	                           LDPARAMS='ROMLEN=384K RAMLEN=64K'

stm32f303xe :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32f303.S' \
	                           FWDEFS='STM32F3 STM32F303xE USBD_ASM_DRIVER' \
	                           LDPARAMS='ROMLEN=512K RAMLEN=64K'

stm32f429xe :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m4' \
	                           FWSTARTUP='mcu/stm32f4xx.S' \
	                           FWDEFS='STM32F4 STM32F429xx' \
	                           LDPARAMS='ROMLEN=512K RAMLEN=192K APPALIGN=0x4000'

stm32f429xg :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m4' \
	                           FWSTARTUP='mcu/stm32f4xx.S' \
	                           FWDEFS='STM32F4 STM32F429xx' \
	                           LDPARAMS='ROMLEN=1024K RAMLEN=192K APPALIGN=0x4000'

stm32f429xi :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m4' \
	                           FWSTARTUP='mcu/stm32f4xx.S' \
	                           FWDEFS='STM32F4 STM32F429xx' \
	                           LDPARAMS='ROMLEN=2048K RAMLEN=192K APPALIGN=0x4000'

stm32f105xb :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32f105.S' \
	                           FWDEFS='STM32F1 STM32F105xC USBD_VBUS_DETECT' \
	                           LDPARAMS='ROMLEN=128K RAMLEN=20K'

stm32f107xb :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32f105.S' \
	                           FWDEFS='STM32F1 STM32F107xC HSE_25MHZ USBD_VBUS_DETECT' \
	                           LDPARAMS='ROMLEN=128K RAMLEN=20K'

stm32l433xb :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m4' \
	                           FWSTARTUP='mcu/stm32l4xx.S' \
	                           FWDEFS='STM32L4 STM32L433xx USBD_ASM_DRIVER' \
	                           LDPARAMS='ROMLEN=128K RAMLEN=48K'

stm32l433xc :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m4' \
	                           FWSTARTUP='mcu/stm32l4xx.S' \
	                           FWDEFS='STM32L4 STM32L433xx USBD_ASM_DRIVER' \
	                           LDPARAMS='ROMLEN=256K RAMLEN=48K'
stm32f070x6 :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m0' \
	                           FWSTARTUP='mcu/stm32f0xx.S' \
	                           FWDEFS='STM32F0 STM32F070x6 USBD_ASM_DRIVER' \
	                           LDPARAMS='ROMLEN=32K RAMLEN=6K'

stm32f070xb :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m0' \
	                           FWSTARTUP='mcu/stm32f0xx.S' \
	                           FWDEFS='STM32F0 STM32F070xB USBD_ASM_DRIVER' \
	                           LDPARAMS='ROMLEN=128K RAMLEN=16K'

stm32g431xb :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m4' \
	                           FWSTARTUP='mcu/stm32g4xx.S' \
	                           FWDEFS='STM32G4 STM32G431xx USBD_ASM_DRIVER' \
	                           LDPARAMS='ROMLEN=128K RAMLEN=22K'

stm32g474xb :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m4' \
	                           FWSTARTUP='mcu/stm32g4xx.S' \
	                           FWDEFS='STM32G4 STM32G474xx USBD_ASM_DRIVER' \
	                           LDPARAMS='ROMLEN=128K RAMLEN=22K'

stm32g474xe :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m4' \
	                           FWSTARTUP='mcu/stm32g4xx.S' \
	                           FWDEFS='STM32G4 STM32G474xx USBD_ASM_DRIVER' \
	                           LDPARAMS='ROMLEN=512K RAMLEN=96K'

.PHONY: clean bootloader crypter all program program_stcube rebuild fwclean $(FWTARGETS)
