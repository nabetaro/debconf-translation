#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Kde::Note - a note to show to the user

=cut

package Debconf::Element::Kde::Note;
use strict;
use Debconf::Gettext;
use Qt;
use Debconf::Element::Noninteractive::Note;
use base qw(Debconf::Element::Kde);

=head1 DESCRIPTION

This is simply a note to display to the user.

=head1 METHODS

=over 4

=item create

Creates and sets up the widget.

=cut

sub create {
	my $this=shift;
	$this->SUPER::create(@_);
	$this->startsect;
	# TODO implement a button to mail the note to user,
	# like gnome frontend has.
	$this->adddescription;
	$this->addhelp;
	$this->endsect;
}

=back

=head1 AUTHOR

Peter Rockai <mornfall@logisys.dyndns.org>

=cut

1
