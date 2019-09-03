include $(PRJROOT)/rules.mk

OBJS := mbr_hd \
	mbr_hd.map \
	boot_hd \
	boot_hd.map

all: $(OBJS)

mbr_hd: mbr_hd.$(BINSUFFIX)
	$(OBJCOPY) -R .pdr -R .comment -R .note \
		-S -O binary $< $@
	@/usr/bin/printf "\e[32mMBR image generated.\e[0m\n"

mbr_hd.$(BINSUFFIX): mbr_hd.o mbr_hd.lds
	$(LD) mbr_hd.o -o $@ -e START -T mbr_hd.lds

boot_hd: boot_hd.$(BINSUFFIX)
	$(OBJCOPY) -R .pdr -R .comment -R .note \
		-S -O binary $< $@
	@/usr/bin/printf "\e[32mBoot image generated.\e[0m\n"

boot_hd.$(BINSUFFIX): boot_hd.o boot_hd.lds
	$(LD) boot_hd.o -o $@ -e START -T boot_hd.lds

clean:
	-@rm -f $(OBJS)
	-@rm -f *.o
	-@rm -f *.$(BINSUFFIX)

