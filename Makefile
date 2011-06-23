MUNGE=xargs perl -i.bak -ne ' \
		print $$_."\# This file was preprocessed, do not edit!\n" \
			if m:^\#!/usr/bin/perl:; \
		$$cutting=1 if /^=/; \
		$$cutting="" if /^=cut/; \
		next if /use lib/; \
		next if $$cutting || /^(=|\s*\#)/; \
		print $$_ \
	'

all:
	$(MAKE) -C doc
	$(MAKE) -C po

clean:
	find . \( -name \*~ -o -name \*.pyc -o -name \*.pyo \) | xargs rm -f
	rm -rf __pycache__
	$(MAKE) -C doc clean
	$(MAKE) -C po clean
	#remove generated file
	rm -f Debconf/FrontEnd/Kde/Ui_DebconfWizard.pm

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

# This would probably be easier if we used setup.py ...
PYTHON2_SUPPORTED := $(shell pyversions -s)
PYTHON_SITEDIR = $(prefix)/usr/lib/$(1)/$(if $(filter 2.0 2.1 2.2 2.3 2.4 2.5,$(patsubst python%,%,$(1))),site-packages,dist-packages)

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
	#build the Qt ui file
	cd $(CURDIR)/Debconf/FrontEnd/Kde/ && bash generateui.sh
	# Make module directories.
	find Debconf -type d |grep -v CVS | \
		xargs -i install -d $(prefix)/usr/share/perl5/{}
	# Install modules.
	find Debconf -type f -name '*.pm' |grep -v CVS | \
		xargs -i install -m 0644 {} $(prefix)/usr/share/perl5/{}
	set -e; for dir in $(foreach python,$(PYTHON2_SUPPORTED),$(call PYTHON_SITEDIR,$(python))); do \
		install -d $$dir; \
		install -m 0644 debconf.py $$dir/; \
	done
	install -d $(prefix)/usr/lib/python3/dist-packages
	install -m 0644 debconf3.py $(prefix)/usr/lib/python3/dist-packages/debconf.py
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
