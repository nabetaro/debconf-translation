#!/usr/bin/perl -w

=head1 NAME

Debconf::Element - Base input element

=cut

package Debconf::Element;
use strict;
use base qw(Debconf::Base);

=head1 DESCRIPTION

This is the base object on which many different types of input elements are
built. Each element represents one user interface element in a FrontEnd. 

=head1 METHODS

=over 4

=item visible

Returns true if an Element is of a type that is displayed to the user.
This is used to let confmodules know if the elements they have caused to be
displayed are really going to be displayed, or not, so they can avoid loops
and other nastiness.

=cut

sub visible {
	my $this=shift;
	
	return 1;
}

=item show

Causes the element to be displayed, allows the user to interact with it to
specify a value, and returns the value they enter (this value is later used to
set the value of the accociated question).

=cut

sub show {}

=item process

Some types of Elements will be called on to process information gotten from
the user. The default process subroutine simply spits the information back,
it may need to be overridden to manipulate the values.

=cut

sub process {
	my $this=shift;
	my $value=shift;

	return $value;
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
