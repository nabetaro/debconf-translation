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

=head1 FIELDS

=over 4

=item value

The value the user entered into the element.

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

Causes the element to be displayed, allows the user to interact with it.
Typically causes the value field to be set.

=cut

sub show {}

=back

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
