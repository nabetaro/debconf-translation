#!/usr/bin/perl -w

=head1 NAME

Debconf::Sigil - smiley sigles

=cut

package Debconf::Sigil::Smiley;
use strict;
use Debconf::Gettext;
use base q{Debconf::Sigil};

=head1 DESCRIPTION

Uses smiley faces as cute little sigils.

=cut

our %sigils=(
	low	 => gettext('|-)'),
	medium	 => gettext(':-)'),
	high	 => gettext(':-!'),
	critical => gettext('=:-O'),
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
