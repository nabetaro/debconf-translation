test:
	./test.pl $(FRONTEND) samples/$(PACKAGE).templates \
		samples/$(PACKAGE).config

clean:
	find . -name \*~ | xargs rm -f
	rm -f *.db

install: clean
  # Install libs
	install -d $(prefix)/usr/lib/perl5/Debian/DebConf/ \
		$(prefix)/var/lib/debconf $(prefix)/usr/share/debconf
	install -m 0644 *.pm $(prefix)/usr/lib/perl5/Debian/DebConf/
	find Client ConfModule Element FrontEnd -type d | grep -v CVS | \
		xargs -i_ install -d $(prefix)/usr/lib/perl5/Debian/DebConf/_
	find Client ConfModule Element FrontEnd -type f | grep .pm\$$ | \
	xargs -i_ install -m 0644 _ $(prefix)/usr/lib/perl5/Debian/DebConf/_
	install -d $(prefix)/etc/
	rm -f $(prefix)/usr/lib/perl5/Debian/DebConf/Config.pm
	cp $(prefix)/usr/lib/perl5/Debian/DebConf/Config-dist.pm \
		$(prefix)/etc/debconf.cfg
	# Should be a link here to Config.pm, debian/rules does it w/dh_link.	
	mv $(prefix)/usr/lib/perl5/Debian/DebConf/Config-dist.pm \
		$(prefix)/usr/lib/perl5/Debian/DebConf/Config.pm
	install -m 0644 Client/confmodule.sh $(prefix)/usr/share/debconf/

  # Generate man pages from POD docs.
	install -d $(prefix)/usr/share/man/man2/
	pod2man Client/ConfModule.pm > $(prefix)/usr/share/man/man2/Debian::Debconf::Client::ConfModule.2pm

  # Install bins
	install -d $(prefix)/usr/bin
	find Client -perm +1 -type f | xargs -i_ install _ $(prefix)/usr/bin
