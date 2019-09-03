include $(PRJROOT)/rules.mk

SRCS = $(wildcard *.c)
OBJS = $(patsubst %.c,%.o,$(SRCS))

ifeq ("$(HOSTOS)", "WIN")
TOOLNAME = wrtosbtl.exe
else
ifeq ("$(HOSTOS)", "GNU")
TOOLNAME = wrtosbtl
endif
endif

ifeq ("$(HOST)", "x86")
CC = gcc
LD = ld
endif

.PHONY : all

all: $(TOOLNAME)

$(TOOLNAME): $(OBJS)
	$(CC) $< -o $@
	@/usr/bin/printf "\e[32m"$(TOOLNAME)" generated.\e[0m\n"

clean:
	rm -f $(OBJS) $(TOOLNAME)

