FENNEL := fennel --use-bit-lib

FNL := $(shell \
	find plugin ftplugin after/plugin after/ftplugin -type f -name '*.fnl' 2>/dev/null; \
	find . -maxdepth 1 -name 'init.fnl' \
)

LUA := $(FNL:.fnl=.lua)

all: $(LUA)

%.lua: %.fnl
	@$(FENNEL) --compile $< > $@
	@echo "pass: $<"

clean:
	rm -f $(LUA)

update:
	nix flake update
	git add flake.lock
	git commit -m "update"
	git push
	cd ..
	gh run list
	echo gh run view

.PHONY: all clean
