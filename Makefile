prefix ?= /usr

.PHONY: all

all:
	echo "Nothing to build."

install:
	perl installer.pl -install -prefix "$(prefix)" "$(target)"

uninstall:
	perl installer.pl -remove -prefix "$(prefix)" "$(target)"

clean:
	echo "Nothing to clean up."
