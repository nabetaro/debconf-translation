all: Version.pm
	$(MAKE) -C doc

VERSION=$(shell expr "`dpkg-parsechangelog 2>/dev/null |grep Version:`" : '.*Version: \(.*\)')
Version.pm:
	echo -e "package Debian::DebConf::Version;\n\$$version='$(VERSION)';" > Version.pm

test:
	samples/$(PACKAGE)

clean:
	find . -name \*~ | xargs rm -f
	rm -f *.db Version.pm
	$(MAKE) -C doc clean

install-common:
	install -d $(prefix)/usr/lib/perl5/Debian/DebConf/ \
		$(prefix)/var/lib/debconf \
		$(prefix)/usr/share/debconf/templates
	chmod 700 $(prefix)/var/lib/debconf
	install -m 0644 *.pm $(prefix)/usr/lib/perl5/Debian/DebConf/
	find Client Element FrontEnd -type d | grep -v CVS | \
		xargs -i_ install -d $(prefix)/usr/lib/perl5/Debian/DebConf/_
	find Client Element FrontEnd -type f | grep .pm\$$ | \
		xargs -i_ install -m 0644 _ $(prefix)/usr/lib/perl5/Debian/DebConf/_
	install -m 0644 Client/confmodule.sh Client/confmodule $(prefix)/usr/share/debconf/
	install Client/frontend $(prefix)/usr/share/debconf/
	 # Modify config module to use correct db location.
	sed 's:.*# CHANGE THIS AT INSTALL TIME:"/var/lib/debconf/":' \
		< Config.pm > $(prefix)/usr/lib/perl5/Debian/DebConf/Config.pm

install: install-common
	# Generate man pages from POD docs.
	install -d $(prefix)/usr/share/man/man3/
	pod2man Client/ConfModule.pm > $(prefix)/usr/share/man/man3/Debian::Debconf::Client::ConfModule.3pm
	# Install bins
	install -d $(prefix)/usr/sbin
	find Client -perm +1 -type f | grep -v frontend | \
		xargs -i_ install _ $(prefix)/usr/sbin

# This target installs a minimal debconf.
tiny-install: install-common
	# Delete the libs we don't need.
	find $(prefix)/usr/lib/perl5/Debian/DebConf/ | egrep 'Text|Web|Gtk' \
		| grep -v Dialog/ | xargs rm -rf
	# Strip out POD documentation and all other comments
	# from all .pm files.
	find $(prefix)/usr/lib/perl5/Debian/DebConf/ -name '*.pm' | \
		xargs perl -i.bak -ne ' \
			$$cutting=!$$cutting if /^=/; \
			next if $$cutting; \
			print $$_ unless /^(=|\s*#)/ \
		'
	find $(prefix)/usr/lib/perl5/Debian/DebConf/ -name '*.bak' | xargs rm -f
	install -d $(prefix)/usr/sbin $(prefix)/usr/share/man/man8
	install Client/dpkg-reconfigure Client/dpkg-preconfigure \
		$(prefix)/usr/sbin/
	cp Client/dpkg-reconfigure.8 Client/dpkg-preconfigure.8 \
		$(prefix)/usr/share/man/man8
