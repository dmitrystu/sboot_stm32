OUTDIR     ?= build
FWNAME     ?= firmware
SWNAME     ?= fwcrypt
CMSISDIR   ?= ../cmsis

FWTOOLS	   ?= arm-none-eabi-
SWTOOLS    ?=

USBDIR     ?= libusb_stm32
SWCFALGS   ?=


FWCFLAGS    = -mcpu=cortex-m0plus -mfloat-abi=soft -mthumb
FWCPPFLAGS  = -Os -Wall -std=gnu99 -flto -s
FWDEFS      = STM32L0 STM32L052xx
FWINCS      = $(CMSISDIR)/device/ST $(CMSISDIR)/include $(USBDIR) inc
FWSCRIPT    = mcu/stm32l052x8.ld
FWLDFLAGS   = -s -specs=nano.specs -nostartfiles -Wl,--gc-sections -Wl,--script=$(FWSCRIPT) -Wl,-Map=$(OUTDIR)/$(FWNAME).map

SWCFLAGS   += -Os -s
SWLDFLAGS   = -libstd
SWINCS      = inc
SWDEFS      =



CRYPT_SRC = src/arc4.c src/chacha.c src/gost.c src/raiden.c src/rc5.c
USB_SRC   = $(USBDIR)/src/usb_32v0.c $(USBDIR)/src/usbd_core.c $(USBDIR)/src/usb_32l0A.S
FW_SRC    = src/descriptors.c src/bootloader.c $(CRYPT_SRC) $(USB_SRC) \
            src/flash_a.S src/rc5a.S mcu/stm32l0xx.S src/chacha_a.S
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
	@echo linking $@
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
	$(RM) $(OUTDIR)

.PHONY: clean bootloader crypter all rebuild
