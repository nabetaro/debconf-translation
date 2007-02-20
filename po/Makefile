# List here all source files with translatable strings.
POTFILES=$(sort $(shell find ../Debconf -type f -name \*.pm)) \
	../dpkg-* ../debconf-* ../debconf

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
	@echo "Rebuilding the pot file"
	xgettext $(POTFILES) -o debconf.pot -Lperl

clean:
	rm -f $(MOFILES) messages messages.mo

%.mo: %.po
	msgfmt -o $@ $<

%.po: debconf.pot
	@echo -n "Merging debconf.pot and $@"
	@msgmerge $@ debconf.pot -o $@.new
# Typically all that changes was a date or line number. I'd prefer not to
# commit such changes, so detect and ignore them.
	@if [ "`diff $@ $@.new | grep '[<>]' | grep -v '[<>] #:' | wc -l`" -ne 2 ]; then \
		mv -f $@.new $@; \
	else \
		rm -f $@.new; \
	fi
	@msgfmt --statistics $@

check:
	@for file in $(POFILES); do \
		lang=`echo $$file | sed 's/\.po//'`; \
		printf "$$lang: "; \
		msgfmt -o /dev/null -c -v --statistics $$lang.po;\
	done
