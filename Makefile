all:
	$(MAKE) -C doc

test:
	./test.pl $(FRONTEND) samples/$(PACKAGE).templates \
		samples/$(PACKAGE).config

clean:
	find . -name \*~ | xargs rm -f
	rm -f *.db
	$(MAKE) -C doc clean

install:
  # Install libs
	install -d $(prefix)/usr/lib/perl5/Debian/DebConf/ \
		$(prefix)/var/lib/debconf $(prefix)/usr/share/debconf
	chmod 700 $(prefix)/var/lib/debconf
	install -m 0644 *.pm $(prefix)/usr/lib/perl5/Debian/DebConf/
	find Client ConfModule Element FrontEnd -type d | grep -v CVS | \
		xargs -i_ install -d $(prefix)/usr/lib/perl5/Debian/DebConf/_
	find Client ConfModule Element FrontEnd -type f | grep .pm\$$ | \
		xargs -i_ install -m 0644 _ $(prefix)/usr/lib/perl5/Debian/DebConf/_
	install -d $(prefix)/etc/
	install -m 0644 Client/confmodule.sh Client/confmodule $(prefix)/usr/share/debconf/
	install Client/frontend $(prefix)/usr/share/debconf/

  # Modify config module to use correct db location.
	sed 's:.*# CHANGE THIS AT INSTALL TIME:"/var/lib/debconf/":' \
		< Config.pm > $(prefix)/usr/lib/perl5/Debian/DebConf/Config.pm

  # Generate man pages from POD docs.
	install -d $(prefix)/usr/share/man/man3/
	pod2man Client/ConfModule.pm > $(prefix)/usr/share/man/man3/Debian::Debconf::Client::ConfModule.3pm

  # Install bins
	install -d $(prefix)/usr/bin
	find Client -perm +1 -type f | grep -v frontend | \
		xargs -i_ install _ $(prefix)/usr/bin
