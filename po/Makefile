# List here all source files with translatable strings.
POTFILES=$(shell find .. -type f -name \*.pm) ../Client/*.pm \
	../Client/dpkg-* ../Client/debconf-*

POFILES=$(wildcard *.po)
MOFILES=$(POFILES:.po=.mo)

all: debconf.pot $(MOFILES)

install: all
	for file in $(MOFILES); do \
		lang=`echo $$file | sed 's/\.mo//'`; \
		install -d $(prefix)/usr/share/locale/$$lang/LC_MESSAGES/; \
		install -m 0644 $$file $(prefix)/usr/share/locale/$$lang/LC_MESSAGES/debconf.mo; \
	done

debconf.pot: $(POTFILES)
# xgettext can mostly handle perl files as C files, though it gets a bit
# confused about single quotes in comments, and the gettext() calls have to
# use double-quoted strings or it will ignore them.
	xgettext $(POTFILES) -o debconf.pot -Lc

clean:
	rm -f debconf.pot $(MOFILES)

%.mo: %.po
	msgfmt -o $@ $<
