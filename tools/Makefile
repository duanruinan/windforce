include $(PRJROOT)/rules.mk

TOOLDIRS = wrtmbr wrtosbtl

define build_tools
for subdir in $(TOOLDIRS); do \
	if ! [ -d $$subdir ]; then \
		echo "Directory $$subdir is not exist!"; \
		exit 1; \
	fi; \
	echo "Building $$subdir ..."; \
	make -C $$subdir; \
	if [ $$? -ne 0 ]; then \
		echo "Building $$subdir failed!"; \
		exit 1; \
	fi; \
done
endef

define clean_tools
for subdir in $(TOOLDIRS); do \
	if ! [ -d $$subdir ]; then \
		echo "Directory $$subdir is not exist!"; \
		exit 1; \
	fi; \
	echo "Cleaning $$subdir ..."; \
	make -C $$subdir clean; \
	if [ $$? -ne 0 ]; then \
		echo "Cleaning $$subdir failed!"; \
		exit 1; \
	fi; \
done
endef

.PHONY : all

all :
	@/usr/bin/printf "\e[32mBuilding host tools...\e[0m\n"
	@$(call build_tools)

clean:
	@$(call clean_tools)

