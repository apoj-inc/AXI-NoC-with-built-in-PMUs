CCTB_MAKEFILE := $(CURDIR)/cctb/build/makefile

.PHONY: all clean
all:
	make -f $(CCTB_MAKEFILE) run

clean:
	@rm -rf .cache
