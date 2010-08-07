#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Kde::Error - an error message to show to the user

=cut

package Debconf::Element::Kde::Error;
use strict;
use Debconf::Gettext;
use QtCore4;
use QtGui4;
use base qw(Debconf::Element::Kde);

=head1 DESCRIPTION

An error message to display to the user.

=head1 METHODS

=over 4

=item create

Creates and sets up the widget.

=cut

sub create {
	my $this=shift;
	$this->SUPER::create(@_);
	$this->startsect;
	$this->adddescription;
	$this->addhelp;
	$this->endsect;
}

=back

=head1 AUTHOR

Peter Rockai <mornfall@logisys.dyndns.org>
Colin Watson <cjwatson@debian.org>

=cut

1
