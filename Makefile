all:
	$(MAKE) -C doc
	$(MAKE) -C po
	$(MAKE) -C apt

clean:
	find . -name \*~ | xargs rm -f
	$(MAKE) -C doc clean
	$(MAKE) -C po clean
	$(MAKE) -C apt clean

install: install-utils install-docs install-rest

# Man pages that go in the debconf-doc package.
install-man:
	install -d $(prefix)/usr/share/man/man3
	install -d $(prefix)/usr/share/man/man8
	pod2man --section=3 Debconf/Client/ConfModule.pm \
		> $(prefix)/usr/share/man/man3/Debconf::Client::ConfModule.3pm
	install -m 0644 confmodule.3 $(prefix)/usr/share/man/man3/
	install -m 0644 debconf.8 $(prefix)/usr/share/man/man8/

# Anything that goes in the debconf-utils package.
install-utils:
	install -d $(prefix)/usr/bin
	find . -maxdepth 1 -perm +1 -type f -name 'debconf-*' | \
		xargs -i install {} $(prefix)/usr/bin
	# Make man pages for utils.
	install -d $(prefix)/usr/share/man/man1
	find . -maxdepth 1 -perm +1 -type f -name 'debconf-*' | \
		xargs -i sh -c 'pod2man --section=1 {} > $(prefix)/usr/share/man/man1/`basename {}`.1'

# Install all else.
install-rest:
	$(MAKE) -C po install
	install -d \
		$(prefix)/var/lib/debconf \
		$(prefix)/usr/share/debconf/templates \
		$(prefix)/usr/lib/debconf
	chmod 700 $(prefix)/var/lib/debconf
	# Make module directories.
	find Debconf -type d |grep -v CVS | \
		xargs -i install -d $(prefix)/usr/lib/perl5/{}
	# Install modules.
	find Debconf -type f -name '*.pm' |grep -v CVS | \
		xargs -i install -m 0644 {} $(prefix)/usr/lib/perl5/{}
	# Special case for back-compatability.
	install -d $(prefix)/usr/lib/perl5/Debian/DebConf/Client
	cp Debconf/Client/ConfModule.stub \
		$(prefix)/usr/lib/perl5/Debian/DebConf/Client/ConfModule.pm
	# Other libs and helper stuff.
	install -m 0644 confmodule.sh confmodule $(prefix)/usr/share/debconf/
	install frontend $(prefix)/usr/share/debconf/
	install -s apt/apt-extracttemplates $(prefix)/usr/lib/debconf/
	 # Modify config module to use correct db location.
	sed 's:.*# CHANGE THIS AT INSTALL TIME:"/var/lib/debconf/":' \
		< Debconf/Config.pm > $(prefix)/usr/lib/perl5/Debconf/Config.pm
	# Install essential programs.
	install -d $(prefix)/usr/sbin
	find . -maxdepth 1 -perm +1 -type f -name 'dpkg-*' | \
		xargs -i install {} $(prefix)/usr/sbin
	# Make man pages for programs.
	install -d $(prefix)/usr/share/man/man8
	find . -maxdepth 1 -perm +1 -type f -name 'dpkg-*' | \
		xargs -i sh -c 'pod2man --section=8 {} > $(prefix)/usr/share/man/man8/`basename {}`.8'
	# Now strip all pod documentation from all .pm files.
	# Also, don't use 'base', it's not in perl-base.
	find $(prefix)/usr/lib/perl5/ $(prefix)/usr/sbin		\
	     $(prefix)/usr/share/debconf/frontend 			\
	     -name '*.pm' -or -name 'dpkg-*' | 				\
	     grep -v Client/ConfModule | xargs perl -i.bak -ne ' 	\
	     		print $$_."# This file was preprocessed, do not edit directly.\n" \
				if m:^#!/usr/bin/perl:; 		\
	     		$$cutting=1 if /^=/; 				\
	     		$$cutting="" if /^=cut/; 			\
			next if $$cutting || /^(=|\s*#)/ || $$_ eq "\n";\
			if (/(use\s+base\s+q.?[{(])(.*?)([})])/) { 	\
				$$what=$$2; \
				$$use=""; \
				map { $$use.="use $$_;" } split(/\s+/, $$what); \
				print "our \@ISA; $$use push \@ISA, qw{$$what};\n" \
			} 						\
			else {						\
				print $$_				\
			}						\
		'
	find $(prefix) -name '*.bak' | xargs rm -f
