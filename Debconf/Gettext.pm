#!/usr/bin/perl -w

=head1 NAME

Debconf::Gettext - Enables gettext for internationalization.

=cut

package Debconf::Gettext;
use strict;

=head1 DESCRIPTION

This module should be used by any part of debconf that is internationalized
and uses the gettext() function to get translated text. This module will
attempt to use Locale::gettext to provide the gettext() function. However,
since debconf must be usable on the base system, which does not include
Locale::gettext, it will detect if loading the module fails, and fall back
to providing a gettext() function that only works in the C locale.

This module also calls textdomain() if possible; the domain used by debconf
is "debconf".

=cut

BEGIN {
	eval 'use Locale::gettext';
	if ($@) {
		# Failed; make up and export our own stupid gettext() function.
		eval q{
			sub gettext {
				return shift;
			}
		};
	}
	else {
		# Locale::gettext initialized; proceed with setup.
		textdomain('debconf');
	}
}

# Now there is a gettext symbol in our symbol table, which must be exported
# to our caller.
use base qw(Exporter);
our @EXPORT=qw(gettext);

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
