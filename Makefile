MUNGE=xargs perl -i.bak -ne ' \
		print $$_."\# This file was preprocessed, do not edit!\n" \
			if m:^\#!/usr/bin/perl:; \
		$$cutting=1 if /^=/; \
		$$cutting="" if /^=cut/; \
		next if /use lib/; \
		next if $$cutting || /^(=|\s*\#)/; \
		print $$_ \
	'

all: Debconf/FrontEnd/Kde/WizardUi.pm
	$(MAKE) -C doc
	$(MAKE) -C po

Debconf/FrontEnd/Kde/WizardUi.pm: Debconf/FrontEnd/Kde/WizardUi.ui
	LC_ALL=C puic $< |sed 's/package WizardUi/package Debconf::FrontEnd::Kde::WizardUi/' > $@

clean:
	find . \( -name \*~ -o -name \*.pyc -o -name \*.pyo \) | xargs rm -f
	$(MAKE) -C doc clean
	$(MAKE) -C po clean
	rm -f Debconf/FrontEnd/Kde/WizardUi.pm

# Does not attempt to install documentation, as that can be fairly system
# specific.
install: install-utils install-rest

# Anything that goes in the debconf-utils package.
install-utils:
	install -d $(prefix)/usr/bin
	find . -maxdepth 1 -perm +100 -type f -name 'debconf-*' | grep -v debconf-set-selections | grep -v debconf-show | grep -v debconf-copydb | grep -v debconf-communicate | grep -v debconf-apt-progress | grep -v debconf-escape | \
		xargs -i install {} $(prefix)/usr/bin

# Anything that goes in the debconf-i18n package.
install-i18n:
	$(MAKE) -C po install

# Install all else.
install-rest:
	install -d $(prefix)/etc \
		$(prefix)/var/cache/debconf \
		$(prefix)/usr/share/debconf \
		$(prefix)/usr/share/pixmaps
	install -m 0644 debconf.conf $(prefix)/etc/
	install -m 0644 debian-logo.png $(prefix)/usr/share/pixmaps/
	# This one is the ultimate backup copy.
	grep -v '^#' debconf.conf > $(prefix)/usr/share/debconf/debconf.conf
	# Make module directories.
	find Debconf -type d |grep -v CVS | \
		xargs -i install -d $(prefix)/usr/share/perl5/{}
	install -d $(prefix)/usr/lib/python2.3/site-packages/ \
		$(prefix)/usr/lib/python2.4/site-packages/
	# Install modules.
	find Debconf -type f -name '*.pm' |grep -v CVS | \
		xargs -i install -m 0644 {} $(prefix)/usr/share/perl5/{}
	install -m 0644 debconf.py $(prefix)/usr/lib/python2.3/site-packages/
	install -m 0644 debconf.py $(prefix)/usr/lib/python2.4/site-packages/
	# Special case for back-compatability.
	install -d $(prefix)/usr/share/perl5/Debian/DebConf/Client
	cp Debconf/Client/ConfModule.stub \
		$(prefix)/usr/share/perl5/Debian/DebConf/Client/ConfModule.pm
	# Other libs and helper stuff.
	install -m 0644 confmodule.sh confmodule $(prefix)/usr/share/debconf/
	install frontend $(prefix)/usr/share/debconf/
	install -m 0755 transition_db.pl fix_db.pl $(prefix)/usr/share/debconf/
	# Install essential programs.
	install -d $(prefix)/usr/sbin $(prefix)/usr/bin
	find . -maxdepth 1 -perm +100 -type f -name 'dpkg-*' | \
		xargs -i install {} $(prefix)/usr/sbin
	find . -maxdepth 1 -perm +100 -type f -name debconf -or -name debconf-show -or -name debconf-copydb -or -name debconf-communicate -or -name debconf-set-selections -or -name debconf-apt-progress -or -name debconf-escape | \
		xargs -i install {} $(prefix)/usr/bin
	# Now strip all pod documentation from all .pm files and scripts.
	find $(prefix)/usr/share/perl5/ $(prefix)/usr/sbin		\
	     $(prefix)/usr/share/debconf/frontend 			\
	     $(prefix)/usr/share/debconf/*.pl $(prefix)/usr/bin		\
	     -name '*.pl' -or -name '*.pm' -or -name 'dpkg-*' -or	\
	     -name 'debconf-*' -or -name 'frontend' | 			\
	     grep -v Client/ConfModule | $(MUNGE)
	find $(prefix) -name '*.bak' | xargs rm -f

demo:
	PERL5LIB=. ./frontend samples/demo
