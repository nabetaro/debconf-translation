test:
	./test.pl $(FRONTEND) samples/$(PACKAGE).templates \
		samples/$(PACKAGE).mappings samples/$(PACKAGE).config

clean:
	find . -name \*~ | xargs rm -f

install: clean
  # Install libs
	install -d $(prefix)/usr/lib/perl5/Debian/DebConf/
	install -m 0644 *.pm $(prefix)/usr/lib/perl5/Debian/DebConf/
	find Client ConfModule Element FrontEnd -type d | grep -v CVS | \
		xargs -i_ install -d $(prefix)/usr/lib/perl5/Debian/DebConf/_
	find Client ConfModule Element FrontEnd -type f | grep .pm\$$ | \
	xargs -i_ install -m 0644 _ $(prefix)/usr/lib/perl5/Debian/DebConf/_
	
  # Generate man pages from POD docs.
	install -d $(prefix)/usr/man/man2/
	pod2man Client/ConfModule.pm > $(prefix)/usr/man/man2/Debian::Debconf::Client::ConfModule.2pm

  # Install bins
	install -d $(prefix)/usr/bin
	find Client -perm +1 -type f | xargs -i_ install _ $(prefix)/usr/bin
