#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element - Base input element

=cut

package Debian::DebConf::Element;
use strict;
use base qw(Debian::DebConf::Base);

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

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
