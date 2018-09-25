OUTDIR     ?= build
FWNAME     ?= firmware
SWNAME     ?= fwcrypt
FWTOOLS    ?= arm-none-eabi-
CMSIS      ?= ../CMSIS
CMSISDEV   ?= $(CMSIS)/Device

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

#default CPU target
FWCPU	   ?= -mcpu=cortex-m0plus -mfloat-abi=soft
FWDEFS     ?= STM32L0 STM32L052xx
FWSTARTUP  ?= mcu/stm32l0xx.S
FWSCRIPT   ?= mcu/stm32l0xxx8.ld

#sources
CRYPT_SRC   = src/arc4.c src/chacha.c src/gost.c src/raiden.c src/rc5.c src/speck.c src/xtea.c
FW_SRC      = $(CRYPT_SRC) $(FWSTARTUP) src/descriptors.c src/bootloader.c src/rc5a.S src/chacha_a.S
SW_SRC      = $(CRYPT_SRC) src/encrypter.c

#folders
FWODIR    = $(OUTDIR)/objfw
SWODIR    = $(OUTDIR)/objsw
SRCPATH   = $(sort $(dir $(FW_SRC)))
vpath %.c $(SRCPATH)
vpath %.S $(SRCPATH)

#includes
CMSISINC    = $(CMSISDEV)/ST $(CMSIS)/CMSIS/Include
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
FWCFLAGS    = -mthumb -Os -Wall -std=gnu99
FWXFLAGS    = -flto

#linker flags
FWLDFLAGS   = -specs=nano.specs -nostartfiles -Wl,--gc-sections -Wl,-Map=$(OUTDIR)/$(FWNAME).map
SWLDFLAGS   = -libstd



all: bootloader crypter

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

.SECONDARY $(OUTDIR)/$(FWNAME).elf: $(FWOBJ) $(MLIBS)
	@echo building bootloader
	@$(FWTOOLS)gcc $(FWCPU) $(FWCFLAGS) $(FWLDFLAGS) -Wl,--script=$(FWSCRIPT) $(FWOBJ) $(addprefix -l, $(MODULES)) -L$(FWODIR) -o $@


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

stm32l100x6a :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L100xBA USBD_ASM_DRIVER' \
	                           FWSCRIPT='mcu/stm32l100x6a.ld'

stm32l100x8a :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L100xBA USBD_ASM_DRIVER' \
	                           FWSCRIPT='mcu/stm32l100x8a.ld'

stm32l100xba :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L100xBA USBD_ASM_DRIVER' \
	                           FWSCRIPT='mcu/stm32l100xba.ld'

stm32l100xc :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L100xC USBD_ASM_DRIVER' \
	                           FWSCRIPT='mcu/stm32l100xc.ld'

stm32l151x6a :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L151xBA' \
	                           FWSCRIPT='mcu/stm32l1xxx6a.ld'

stm32l151x8a :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L151xBA' \
	                           FWSCRIPT='mcu/stm32l1xxx8a.ld'

stm32l151xba :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L151xBA' \
	                           FWSCRIPT='mcu/stm32l1xxxba.ld'

stm32l151xc :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L151xC' \
	                           FWSCRIPT='mcu/stm32l1xxxc.ld'

stm32l151xd :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L151xD' \
	                           FWSCRIPT='mcu/stm32l1xxxd.ld'

stm32l151xe :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L151xE' \
	                           FWSCRIPT='mcu/stm32l1xxxe.ld'

stm32l152x6a :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L152xBA' \
	                           FWSCRIPT='mcu/stm32l1xxx6a.ld'

stm32l152x8a :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L152xBA' \
	                           FWSCRIPT='mcu/stm32l1xxx8a.ld'

stm32l152xba :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L152xBA' \
	                           FWSCRIPT='mcu/stm32l1xxxba.ld'

stm32l152xc :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L152xC' \
	                           FWSCRIPT='mcu/stm32l1xxxc.ld'

stm32l152xd :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L152xD' \
	                           FWSCRIPT='mcu/stm32l1xxxd.ld'

stm32l152xe :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L152xE' \
	                           FWSCRIPT='mcu/stm32l1xxxe.ld'

stm32l162xc :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L162xC' \
	                           FWSCRIPT='mcu/stm32l1xxxc.ld'

stm32l162xd :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L162xD' \
	                           FWSCRIPT='mcu/stm32l1xxxd.ld'

stm32l162xe :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32l1xx.S' \
	                           FWDEFS='STM32L1 STM32L162xE' \
	                           FWSCRIPT='mcu/stm32l1xxxe.ld'

stm32l052x6 :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m0plus' \
	                           FWSTARTUP='mcu/stm32l0xx.S' \
	                           FWDEFS='STM32L0 STM32L052xx USBD_ASM_DRIVER' \
	                           FWSCRIPT='mcu/stm32l0xxx6.ld'

stm32l052x8 :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m0plus' \
	                           FWSTARTUP='mcu/stm32l0xx.S' \
	                           FWDEFS='STM32L0 STM32L052xx USBD_ASM_DRIVER' \
	                           FWSCRIPT='mcu/stm32l0xxx8.ld'

stm32l053x6 :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m0plus' \
	                           FWSTARTUP='mcu/stm32l0xx.S' \
	                           FWDEFS='STM32L0 STM32L053xx' \
	                           FWSCRIPT='mcu/stm32l0xxx6.ld'

stm32l053x8 :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m0plus' \
	                           FWSTARTUP='mcu/stm32l0xx.S' \
	                           FWDEFS='STM32L0 STM32L053xx' \
	                           FWSCRIPT='mcu/stm32l0xxx8.ld'

stm32l062x8 :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m0plus' \
	                           FWSTARTUP='mcu/stm32l0xx.S' \
	                           FWDEFS='STM32L0 STM32L062xx' \
	                           FWSCRIPT='mcu/stm32l0xxx8.ld'

stm32l063x8 :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m0plus' \
	                           FWSTARTUP='mcu/stm32l0xx.S' \
	                           FWDEFS='STM32L0 STM32L063xx' \
	                           FWSCRIPT='mcu/stm32l0xxx8.ld'

stm32l072v8 :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m0plus' \
	                           FWSTARTUP='mcu/stm32l0xx.S' \
	                           FWDEFS='STM32L0 STM32L072xx' \
	                           FWSCRIPT='mcu/stm32l0xxv8.ld'

stm32l072xb :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m0plus' \
	                           FWSTARTUP='mcu/stm32l0xx.S' \
	                           FWDEFS='STM32L0 STM32L072xx' \
	                           FWSCRIPT='mcu/stm32l0xxxb.ld'

stm32l072xc :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m0plus' \
	                           FWSTARTUP='mcu/stm32l0xx.S' \
	                           FWDEFS='STM32L0 STM32L072xx' \
	                           FWSCRIPT='mcu/stm32l0xxxc.ld'

stm32l073v8 :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m0plus' \
	                           FWSTARTUP='mcu/stm32l0xx.S' \
	                           FWDEFS='STM32L0 STM32L073xx' \
	                           FWSCRIPT='mcu/stm32l0xxv8.ld'

stm32l073xb :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m0plus' \
	                           FWSTARTUP='mcu/stm32l0xx.S' \
	                           FWDEFS='STM32L0 STM32L073xx' \
	                           FWSCRIPT='mcu/stm32l0xxxb.ld'

stm32l073xc :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m0plus' \
	                           FWSTARTUP='mcu/stm32l0xx.S' \
	                           FWDEFS='STM32L0 STM32L073xx' \
	                           FWSCRIPT='mcu/stm32l0xxxc.ld'

stm32l476xc :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m4' \
	                           FWSTARTUP='mcu/stm32l4xx.S' \
	                           FWDEFS='STM32L4 STM32L476xx' \
	                           FWSCRIPT='mcu/stm32l4xxxc.ld'

stm32l476xe :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m4' \
	                           FWSTARTUP='mcu/stm32l4xx.S' \
	                           FWDEFS='STM32L4 STM32L476xx' \
	                           FWSCRIPT='mcu/stm32l4xxxe.ld'

stm32l476xg :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m4' \
	                           FWSTARTUP='mcu/stm32l4xx.S' \
	                           FWDEFS='STM32L4 STM32L476xx' \
	                           FWSCRIPT='mcu/stm32l4xxxg.ld'

stm32f103x4 :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32f103.S' \
	                           FWDEFS='STM32F1 STM32F103x6 USBD_ASM_DRIVER' \
	                           FWSCRIPT='mcu/stm32f1xxx4.ld'

stm32f103x6 :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32f103.S' \
	                           FWDEFS='STM32F1 STM32F103x6 USBD_ASM_DRIVER'\
	                           FWSCRIPT='mcu/stm32f1xxx6.ld'

stm32f103x8 :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32f103.S' \
	                           FWDEFS='STM32F1 STM32F103x6 USBD_ASM_DRIVER' \
	                           FWSCRIPT='mcu/stm32f1xxx8.ld'

stm32f103xb :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32f103.S' \
	                           FWDEFS='STM32F1 STM32F103x6 USBD_ASM_DRIVER' \
	                           FWSCRIPT='mcu/stm32f1xxxb.ld'

stm32f303xb :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32f303.S' \
	                           FWDEFS='STM32F3 STM32F303xB USBD_ASM_DRIVER' \
	                           FWSCRIPT='mcu/stm32f3xxxb.ld'

stm32f303xc :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32f303.S' \
	                           FWDEFS='STM32F3 STM32F303xB USBD_ASM_DRIVER' \
	                           FWSCRIPT='mcu/stm32f3xxxc.ld'

stm32f303xd :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32f303.S' \
	                           FWDEFS='STM32F3 STM32F303xE USBD_ASM_DRIVER' \
	                           FWSCRIPT='mcu/stm32f3xxxd.ld'

stm32f303xe :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32f303.S' \
	                           FWDEFS='STM32F3 STM32F303xE USBD_ASM_DRIVER' \
	                           FWSCRIPT='mcu/stm32f3xxxe.ld'

stm32f429xe :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m4' \
	                           FWSTARTUP='mcu/stm32f4xx.S' \
	                           FWDEFS='STM32F4 STM32F429xx USBD_SOF_DISABLE' \
	                           FWSCRIPT='mcu/stm32f4xxxg.ld'

stm32f429xg :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m4' \
	                           FWSTARTUP='mcu/stm32f4xx.S' \
	                           FWDEFS='STM32F4 STM32F429xx USBD_SOF_DISABLE' \
	                           FWSCRIPT='mcu/stm32f4xxxg.ld'

stm32f429xi :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m4' \
	                           FWSTARTUP='mcu/stm32f4xx.S' \
	                           FWDEFS='STM32F4 STM32F429xx USBD_SOF_DISABLE' \
	                           FWSCRIPT='mcu/stm32f4xxxi.ld'

stm32f105xb :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32f105.S' \
	                           FWDEFS='STM32F1 STM32F105xC USBD_VBUS_DETECT USBD_SOF_DISABLED' \
	                           FWSCRIPT='mcu/stm32f1xxxb.ld'

stm32f107xb :
	$(MAKE) fwclean bootloader FWCPU='-mcpu=cortex-m3' \
	                           FWSTARTUP='mcu/stm32f105.S' \
	                           FWDEFS='STM32F1 STM32F107xC HSE_25MHZ USBD_VBUS_DETECT USBD_SOF_DISABLED' \
	                           FWSCRIPT='mcu/stm32f1xxxb.ld'

.PHONY: clean bootloader crypter all program rebuild fwclean $(FWTARGETS)
