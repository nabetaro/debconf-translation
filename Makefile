all:
	$(MAKE) -C doc
	$(MAKE) -C po
	$(MAKE) -C Client/preconfigure

test:
	-install -d Debian
	-cd Debian && ln -s .. DebConf
	samples/$(PACKAGE)
	rm -rf Debian

clean:
	find . -name \*~ | xargs rm -f
	rm -f *.db Version.pm
	$(MAKE) -C doc clean
	$(MAKE) -C po clean
	$(MAKE) -C Client/preconfigure clean

install-man:
	install -d $(prefix)/usr/share/man/man3
	pod2man --section=3 Client/ConfModule.pm \
		> $(prefix)/usr/share/man/man3/Debian::Debconf::Client::ConfModule.3pm
	install -m 0644 Client/confmodule.3 $(prefix)/usr/share/man/man3/

install-utils:
	install -d $(prefix)/usr/bin
	find Client -perm +1 -type f | grep debconf- | \
		xargs -i_ install _ $(prefix)/usr/bin
	# Make man pages for utils.
	install -d $(prefix)/usr/share/man/man1
	find Client -perm +1 -type f | grep debconf- | \
		xargs -i_ sh -c 'pod2man --section=1 _ > $(prefix)/usr/share/man/man1/`basename _`.1'

install:
	$(MAKE) -C po install
	install -d $(prefix)/usr/lib/perl5/Debian/DebConf/ \
		$(prefix)/var/lib/debconf \
		$(prefix)/usr/share/debconf/templates \
		$(prefix)/usr/lib/debconf
	chmod 700 $(prefix)/var/lib/debconf
	# Install modules.
	install -m 0644 *.pm $(prefix)/usr/lib/perl5/Debian/DebConf/
	find Client Element FrontEnd -type d | grep -v CVS | \
		xargs -i_ install -d $(prefix)/usr/lib/perl5/Debian/DebConf/_
	find Client Element FrontEnd -type f | grep .pm\$$ | \
		xargs -i_ install -m 0644 _ $(prefix)/usr/lib/perl5/Debian/DebConf/_
	# Other libs and helper stuff.
	install -m 0644 Client/confmodule.sh Client/confmodule $(prefix)/usr/share/debconf/
	install Client/frontend $(prefix)/usr/share/debconf/
	install -s Client/preconfigure/apt-extracttemplates $(prefix)/usr/lib/debconf/
	 # Modify config module to use correct db location.
	sed 's:.*# CHANGE THIS AT INSTALL TIME:"/var/lib/debconf/":' \
		< Config.pm > $(prefix)/usr/lib/perl5/Debian/DebConf/Config.pm
	# Install essential programs.
	install -d $(prefix)/usr/sbin
	find Client -perm +1 -type f | grep dpkg- | \
		xargs -i_ install _ $(prefix)/usr/sbin
	# Make man pages for programs.
	install -d $(prefix)/usr/share/man/man8
	find Client -perm +1 -type f | grep dpkg- | \
		xargs -i_ sh -c 'pod2man --section=8 _ > $(prefix)/usr/share/man/man8/`basename _`.8'
	# Now strip all pod documentation from all .pm files.
	# Also, don't use 'base'.
	find $(prefix)/usr/lib/perl5/Debian/DebConf/ $(prefix)/usr/sbin \
	     $(prefix)/usr/share/debconf/frontend \
	     -name '*.pm' -or -name 'dpkg-*' | xargs perl -i.bak -ne ' 	\
	     		print $$_."# This file was preprocessed, do not edit directly.\n" \
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
