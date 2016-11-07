OUTDIR     ?= build
FWNAME     ?= firmware
SWNAME     ?= fwcrypt
CMSISDIR   ?= ../cmsis

FWTOOLS	   ?= arm-none-eabi-
SWTOOLS    ?=

USBDIR     ?= libusb_stm32
SWCFALGS   ?=

FWDEFS     += FORCE_ASM_DRIVER


FWTARGETS  = stm32l100x6a stm32l100x8a stm32l100xba stm32l100xc stm32l151x6a stm32l151x8a stm32l151xba
FWTARGETS += stm32l052x8 

FWCFLAGS   ?= -mcpu=cortex-m0plus -mfloat-abi=soft -mthumb
FWDEFS     ?= STM32L0 STM32L052xx
FWSTARTUP  ?= mcu/stm32l0xx.S
FWSCRIPT   ?= mcu/stm32l52x8.ld

FWCPPFLAGS  = -Os -Wall -std=gnu99 -flto -s
FWINCS      = $(CMSISDIR)/device/ST $(CMSISDIR)/include $(USBDIR) inc
FWLDFLAGS   = -s -specs=nano.specs -nostartfiles -Wl,--gc-sections -Wl,--script=$(FWSCRIPT) -Wl,-Map=$(OUTDIR)/$(FWNAME).map

FWDEFS     += FORCE_ASM_DRIVER


SWCFLAGS   += -Os -s
SWLDFLAGS   = -libstd
SWINCS      = inc
SWDEFS      =


CRYPT_SRC = src/arc4.c src/chacha.c src/gost.c src/raiden.c src/rc5.c
USB_SRC   = $(wildcard $(USBDIR)/src/*.c) $(wildcard $(USBDIR)/src/*.S)
FW_SRC    = $(CRYPT_SRC) $(USB_SRC) $(FWSTARTUP) \
			src/descriptors.c src/bootloader.c src/flash_a.S src/rc5a.S src/chacha_a.S
SW_SRC    = src/encrypter.c $(CRYPT_SRC)

FWODIR    = $(OUTDIR)/objfw
SWODIR    = $(OUTDIR)/objsw


FWOBJ     = $(addprefix $(FWODIR)/, $(addsuffix .o, $(notdir $(basename $(FW_SRC)))))
SWOBJ     = $(addprefix $(SWODIR)/, $(addsuffix .o, $(notdir $(basename $(SW_SRC)))))
SRCPATH   = $(sort $(dir $(FW_SRC)))



ifeq ($(OS),Windows_NT)
	RM = rd /s /q
else
	RM = rm -rf
endif


vpath %.c $(SRCPATH)
vpath %.S $(SRCPATH)


all: bootloader crypter

rebuild: clean all

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

$(OUTDIR)/$(FWNAME).elf: $(FWOBJ)
	@echo building bootloader for $(FWTARGET)
	@$(FWTOOLS)gcc $(FWCFLAGS) $(FWLDFLAGS) $(FWOBJ) -o $@


$(SWOBJ): | $(SWODIR)

$(FWOBJ): | $(FWODIR) $(USB_SRC)

$(OUTDIR):
	@mkdir $@

$(FWODIR) $(SWODIR): | $(OUTDIR)
	@cd $(OUTDIR) && mkdir $(lastword $(subst /, ,$@)) && cd ..

$(USB_SRC):
	git clone http://github.com/dmitrystu/usblib_stm32.git

$(SWODIR)/%.o: %.c
	@echo compiling $<
	@$(SWTOOLS)gcc $(SWCFLAGS) $(addprefix -D,$(SWDEFS)) $(addprefix -I,$(SWINCS)) -c $< -o $@

$(FWODIR)/%.o: %.c
	@echo compiling $<
	@$(FWTOOLS)gcc $(FWCFLAGS) $(FWCPPFLAGS) $(addprefix -D,$(FWDEFS)) $(addprefix -I,$(FWINCS)) -c $< -o $@

$(FWODIR)/%.o: %.S
	@echo assembling $<
	@$(FWTOOLS)gcc $(FWCFLAGS) $(addprefix -D,$(FWDEFS)) $(addprefix -I,$(FWINCS)) -c $< -o $@

clean:
	@$(RM) $(OUTDIR)

fwclean:
	@$(RM) $(FWODIR)





stm32l100x6a : 
	$(MAKE) fwclean bootloader FWCFLAGS='-mcpu=cortex-m3 -mfloat-abi=soft -mthumb' FWSTARTUP='mcu/stm32l1xx.S' FWDEFS='STM32L1 STM32L100xBA' FWSCRIPT='mcu/stm32l100x6.ld'

stm32l100x8a : 
	$(MAKE) fwclean bootloader FWCFLAGS='-mcpu=cortex-m3 -mfloat-abi=soft -mthumb' FWSTARTUP='mcu/stm32l1xx.S' FWDEFS='STM32L1 STM32L100xBA' FWSCRIPT='mcu/stm32l100x8.ld'

stm32l100xba : 
	$(MAKE) fwclean bootloader FWCFLAGS='-mcpu=cortex-m3 -mfloat-abi=soft -mthumb' FWSTARTUP='mcu/stm32l1xx.S' FWDEFS='STM32L1 STM32L100xBA' FWSCRIPT='mcu/stm32l100xba.ld'

stm32l100xc : 
	$(MAKE) fwclean bootloader FWCFLAGS='-mcpu=cortex-m3 -mfloat-abi=soft -mthumb' FWSTARTUP='mcu/stm32l1xx.S' FWDEFS='STM32L1 STM32L100xC' FWSCRIPT='mcu/stm32l100xc.ld'

stm32l151x6a :
	$(MAKE) fwclean bootloader FWCFLAGS='-mcpu=cortex-m3 -mfloat-abi=soft -mthumb' FWSTARTUP='mcu/stm32l1xx.S' FWDEFS='STM32L1 STM32L151xBA' FWSCRIPT='mcu/stm32l151x6a.ld'

stm32l151x8a :
	$(MAKE) fwclean bootloader FWCFLAGS='-mcpu=cortex-m3 -mfloat-abi=soft -mthumb' FWSTARTUP='mcu/stm32l1xx.S' FWDEFS='STM32L1 STM32L151xBA' FWSCRIPT='mcu/stm32l151x8a.ld'

stm32l151xba :
	$(MAKE) fwclean bootloader FWCFLAGS='-mcpu=cortex-m3 -mfloat-abi=soft -mthumb' FWSTARTUP='mcu/stm32l1xx.S' FWDEFS='STM32L1 STM32L151xBA' FWSCRIPT='mcu/stm32l151xba.ld'

stm32l052x8 :
	$(MAKE) fwclean bootloader FWCFLAGS='-mcpu=cortex-m0plus -mfloat-abi=soft -mthumb' FWSTARTUP='mcu/stm32l0xx.S' FWDEFS='STM32L0 STM32L052xx' FWSCRIPT='mcu/stm32l52x8.ld'

.PHONY: clean bootloader crypter all rebuild fwclean $(FWTARGETS)
