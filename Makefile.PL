#!/usr/bin/perl -w
use ExtUtils::MakeMaker;
use strict;

# Just to make it ignore editor backup files.
sub MY::libscan {
	$_ = $_[1];

	return '' if m/\/(RCS|CVS|SCCS)\// ||
	   	     m/[~%]$/ || m/\.(orig|rej)$/ ||
		     m/graph\.pl/;
	return $_;
}

# Add more targets.
sub MY::postamble {
	return <<'eof';
pure_install ::
	install -d $(prefix)/var/lib/debconf \
		$(prefix)/usr/share/debconf/templates \
		$(prefix)/usr/lib/debconf
	chmod 700 $(prefix)/var/lib/debconf
	install -m 0644 confmodule.sh confmodule $(prefix)/usr/share/debconf/
	cp confmodule.3 $(INSTALLMAN3DIR)
	install frontend $(prefix)/usr/share/debconf/
	install -s apt/apt-extracttemplates $(prefix)/usr/lib/debconf/
eof
}

WriteMakefile(
    'NAME'		=> 'Debconf',
    'EXE_FILES'		=> [qw{debconf-communicate debconf-getlang 
                              debconf-loadtemplate debconf-mergetemplate
			      dpkg-preconfigure dpkg-reconfigure}],
    'MAN3PODS'		=> {'Debconf/Client/ConfModule.pm' => '$(INST_MAN3DIR)/Debconf::Client::ConfModule.$(MAN3EXT)'},
);
