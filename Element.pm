#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element - Base input element

=cut

=head1 DESCRIPTION

This is the base object on which many different types of input elements are
built. Each element represents one user interface element in a FrontEnd. Elements
can have associated values which are accessed and set in the usual way.

=cut

=head1 METHODS

=cut

package Debian::DebConf::Element;
use strict;
use vars qw($AUTOLOAD);

=head2 new

Returns a new object of this class.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {};
	bless ($self, $class);
	return $self;
}

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

# Set/get property.
sub AUTOLOAD {
	my $this=shift;
	my $property = $AUTOLOAD;
	$property =~ s|.*:||; # strip fully-qualified portion
	
	$this->{$property}=shift if @_;
	return $this->{$property};
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
