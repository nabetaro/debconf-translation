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
	mv $(prefix)/usr/lib/perl5/Debian/DebConf/Config-dist.pm \
		$(prefix)/usr/lib/perl5/Debian/DebConf/Config.pm
	install -m 0644 Client/confmodule.sh $(prefix)/usr/share/debconf/

  # Generate man pages from POD docs.
	install -d $(prefix)/usr/man/man2/
	pod2man Client/ConfModule.pm > $(prefix)/usr/man/man2/Debian::Debconf::Client::ConfModule.2pm

  # Install bins
	install -d $(prefix)/usr/bin
	find Client -perm +1 -type f | xargs -i_ install _ $(prefix)/usr/bin

# This is for local use - it tags the current code with the devian version
# number, then commits the current code using the contents of the changelog
# as the cvs changelog, then increments the version number
commit: clean
	cvs -Q commit -m "`dpkg-parsechangelog | grep '^  '`"
	cvs -Q tag rel-$(shell dpkg-parsechangelog | grep ^Version: \
		|cut -d " " -f 2 |tr '.' '-')
	$(MAKE) new
	
new:
	# Update w/o editing.
	EDITOR=true dch -i 2>/dev/null
	# Dch has to change the bloody directory name. Feh.
	mv . ../debconf
	
