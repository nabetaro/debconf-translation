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
	return <<eof;
# Test w/o installing. See doc/EXAMPLES
demo:
	samples/$(PACKAGE)

eof
}

WriteMakefile(
    'NAME'		=> 'Debconf',
    'MAN3PODS'		=> {'Debconf/Client/ConfModule.pm' => 'Debconf/Client/ConfModule.pm'},
    'EXE_FILES'		=> [qw{debconf-communicate debconf-getlang 
                              debconf-loadtemplate debconf-mergetemplate
			      dpkg-preconfigure dpkg-reconfigure}],
);
