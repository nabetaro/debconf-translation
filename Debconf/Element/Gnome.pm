#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Gnome - element containing a slang widget

=cut

package Debian::DebConf::Element::Gnome;
use strict;
use Debian::DebConf::Element; # perlbug
use base qw(Debian::DebConf::Element);

=head1 DESCRIPTION

This is a type of Element used by the slang FrontEnd. It contains a Widget
from Term::Stool.

=head1 FIELDS

=over 4

=item widget

This is the primary input widget associated with this Element. It should
automatically be made when this Element is instantiated.

=back

=head1 METHODS

=over 4

=item value

Return the value the user entered.

Defaults to returning nothing.

=cut

sub value {
	my $this=shift;

	return '';
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
