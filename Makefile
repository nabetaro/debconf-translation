all: Version.pm
	$(MAKE) -C doc

VERSION=$(shell expr "`dpkg-parsechangelog 2>/dev/null |grep Version:`" : '.*Version: \(.*\)')
Version.pm:
	echo -e "package Debian::DebConf::Version;\n\$$version='$(VERSION)';" > Version.pm

test:
	-install -d Debian
	-cd Debian && ln -s .. DebConf
	samples/$(PACKAGE)
	rm -rf Debian

clean:
	find . -name \*~ | xargs rm -f
	rm -f *.db Version.pm
	$(MAKE) -C doc clean

install-man:
	install -d $(prefix)/usr/share/man/man3
	pod2man --section=3 Client/ConfModule.pm \
		> $(prefix)/usr/share/man/man3/Debian::Debconf::Client::ConfModule.3pm
	install -m 0644 Client/confmodule.3 $(prefix)/usr/share/man/man3/

install:
	install -d $(prefix)/usr/lib/perl5/Debian/DebConf/ \
		$(prefix)/var/lib/debconf \
		$(prefix)/usr/share/debconf/templates
	chmod 700 $(prefix)/var/lib/debconf
	# Install modules.
	install -m 0644 *.pm $(prefix)/usr/lib/perl5/Debian/DebConf/
	find Client Element FrontEnd -type d | grep -v CVS | \
		xargs -i_ install -d $(prefix)/usr/lib/perl5/Debian/DebConf/_
	find Client Element FrontEnd -type f | grep .pm\$$ | \
		xargs -i_ install -m 0644 _ $(prefix)/usr/lib/perl5/Debian/DebConf/_
	# Other libs.
	install -m 0644 Client/confmodule.sh Client/confmodule $(prefix)/usr/share/debconf/
	install Client/frontend $(prefix)/usr/share/debconf/
	 # Modify config module to use correct db location.
	sed 's:.*# CHANGE THIS AT INSTALL TIME:"/var/lib/debconf/":' \
		< Config.pm > $(prefix)/usr/lib/perl5/Debian/DebConf/Config.pm
	# Install programs.
	install -d $(prefix)/usr/sbin
	find Client -perm +1 -type f | grep -v frontend | \
		xargs -i_ install _ $(prefix)/usr/sbin
	# Make man pages for programs.
	install -d $(prefix)/usr/share/man/man8
	find Client -perm +1 -type f | grep -v frontend | \
		xargs -i_ sh -c 'pod2man --section=8 _ > debian/tmp/usr/share/man/man8/`basename _`.8'
	# Now strip all pod documentation from all .pm files.
	# Also, don't use 'base'.
	find $(prefix)/usr/lib/perl5/Debian/DebConf/ $(prefix)/usr/sbin \
	     $(prefix)/usr/share/debconf/frontend \
	     -name '*.pm' -or -name 'dpkg-*' | xargs perl -i.bak -ne ' 	\
	     		print $$_."# This file has been preprocessed, do not edit directly.\n" \
				if m:^#!/usr/bin/perl:; 		\
	     		$$cutting=1 if /^=/; 				\
	     		$$cutting="" if /^=cut/; 			\
			next if $$cutting || /^(=|\s*#)/ || $$_ eq "\n";\
			if (/(use\s+base\s+q.?[{(])(.*?)([})])/) { 	\
				$$what=$$2; \
				$$use=""; \
				map { $$use.="use $$_;" } split(/\s+/, $$what); \
				print "use vars qw{\@ISA}; $$use push \@ISA, qw{$$what};\n" \
			} 						\
			else {						\
				print $$_				\
			}						\
		'
	find $(prefix) -name '*.bak' | xargs rm -f

