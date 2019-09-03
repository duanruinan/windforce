include $(PRJROOT)/config.mk

ifeq ("$(HOSTOS)", "WIN")
export BINSUFFIX = pe
else
ifeq ("$(HOSTOS)", "GNU")
export BINSUFFIX = elf
endif
endif

%.o : %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o : %.S
	$(CC) $(CFLAGS) -c $< -o $@

%.map : %.$(BINSUFFIX)
	$(NM) $< > $@

