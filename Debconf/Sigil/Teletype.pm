#!/usr/bin/perl -w

=head1 NAME

Debconf::Sigil - Base sigil class

=cut

package Debconf::Sigil::Teletype;
use strict;
use Debconf::Gettext;
use Debconf::Config;
use base q{Debconf::Sigil};

=head1 DESCRIPTION

Sigils for teletypes are smileys by default; more serious alternatives are
also available.

=cut

my %sigils;
if (Debconf::Config->smilies ne 'false') {
	%sigils=(
		low	 => gettext('|-)'),
		medium	 => gettext(':-)'),
		high	 => gettext(':-!'),
		critical => gettext('=:-O'),
	);
}
else {
	%sigils=(
		low	 => gettext('[.]'),
		medium	 => gettext('[?]'),
		high	 => gettext('[!]'),
		critical => gettext('[!!]'),
	);
}

sub get {
	my $this=shift;
	my $priority=shift;
	return $sigils{$priority}." ";
}

=back

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
