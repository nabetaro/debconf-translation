#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Noninteractive - Dummy Element

=cut

=head1 DESCRIPTION

This is noninteractive dummy element. When told to display itself, it does
nothing.

=cut

=head1 METHODS

=cut

package Debian::DebConf::Element::Noninteractive;
use strict;
use base qw(Debian::DebConf::Element);

=head2 visible

This type of element is not visible.

=cut

sub visible {
	my $this=shift;
	
	return;
}

1
