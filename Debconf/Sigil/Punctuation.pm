#!/usr/bin/perl -w

=head1 NAME

Debconf::Sigil - punctuation sigils

=cut

package Debconf::Sigil::Punctuation;
use strict;
use Debconf::Gettext;
use base q{Debconf::Sigil};

=head1 DESCRIPTION

Uses punctuation for sigils.

=cut

our %sigils=(
	low	 => gettext('[.]'),
	medium	 => gettext('[?]'),
	high	 => gettext('[!]'),
	critical => gettext('[!!]'),
);

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
