export PRJROOT = $(shell pwd)
include $(PRJROOT)/rules.mk

ifeq ("$(HOSTOS)", "WIN")
mbrcmd = tools/wrtmbr/wrtmbr boot\\mbr_hd images\\c.img
osbtlcmd = tools/wrtosbtl/wrtosbtl boot\\boot_hd images\\c.img
endif
ifeq ("$(HOSTOS)", "GNU")
mbrcmd = tools/wrtmbr/wrtmbr boot/mbr_hd images/c.img
osbtlcmd = tools/wrtosbtl/wrtosbtl boot/boot_hd images/c.img
endif

.PHONY : ALLBINS
.PHONY : POSTSCRIPT

all: ALLBINS POSTSCRIPT

ALLBINS:
	@/usr/bin/printf "\e[32mSpark: Building started ...\e[0m\n"
	make -C tools
	make -C boot
	cp -f boot/mbr_hd images/
	cp -f boot/mbr_hd.map images/
	cp -f images/empty/$(DISKNAME) images/

POSTSCRIPT:
	@$(mbrcmd)
	@$(osbtlcmd)
	@/usr/bin/printf "\e[32mSpark: Building completely!\e[0m\n"

clean:
	make -C tools clean
	make -C boot clean
	-@rm -f images/c.img

