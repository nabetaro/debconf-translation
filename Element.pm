#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element - Base input element

=cut

=head1 DESCRIPTION

This is the base object on which many different types of input elements are
built. Each element represents one user interface element in a FrontEnd. 

=cut

=head1 METHODS

=cut

package Debian::DebConf::Element;
use strict;
use Debian::DebConf::Base;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Base);

=head2 show

Causes the element to be displayed, allows the user to interact with it to
specify a value, and sets the value in the associated question.

=cut

sub show {}

=head2 visible

The question will determine if it wants to be shown. If so, it returns 1.

=cut

sub visible {
	my $this=shift;

	# Will be shown.
	return 1;
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
