#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Kde::Text - a bit of text to show to the user

=cut

package Debconf::Element::Kde::Text;
use strict;
use Debconf::Gettext;
use Qt;
use base qw(Debconf::Element::Kde);

=head1 DESCRIPTION

This is a bit of text to show to the user.

=cut

sub create {
	my $this=shift;
	$this->SUPER::create(@_);
	$this->startsect;
	$this->adddescription; # yeah, that's all
	$this->endsect;
}

=back

=head1 AUTHOR

Peter Rockai <mornfall@logisys.dyndns.org>

=cut

1
