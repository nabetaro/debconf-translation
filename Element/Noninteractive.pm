#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Noninteractive - Dummy Element

=cut

package Debian::DebConf::Element::Noninteractive;
use strict;
use base qw(Debian::DebConf::Element);

=head1 DESCRIPTION

This is noninteractive dummy element. When told to display itself, it does
nothing.

=head1 METHODS

=over 4

=item visible

This type of element is not visible.

=cut

sub visible {
	my $this=shift;
	
	return;
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
