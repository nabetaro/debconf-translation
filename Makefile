test:
	./test.pl $(FRONTEND) samples/$(PACKAGE).templates \
		samples/$(PACKAGE).mappings samples/$(PACKAGE).config

clean:
	find . -name \*~ | xargs rm -f

install: clean
	install -d $(prefix)/usr/lib/perl5/Debian/DebConf/
	install -m 0644 *.pm $(prefix)/usr/lib/perl5/Debian/DebConf/
	find Client ConfModule Element FrontEnd -type d | grep -v CVS | \
		xargs -i! install -d $(prefix)/usr/lib/perl5/Debian/DebConf/!
	find Client ConfModule Element FrontEnd -type f | grep .pm\$$ | \
		xargs -i! install -m 0644 ! $(prefix)/usr/lib/perl5/Debian/DebConf/!
	install -d $(prefix)/usr/bin
	find client -perm +1 -type f | xargs -i! install ! $(prefix)/usr/bin
