#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Base - Debconf base class

=cut

package Debian::DebConf::Base;
use strict;
use vars qw($AUTOLOAD);

=head1 DESCRIPTION

Objects of this class may have any number of fields. These fields can
be read by calling the method with the same name as the field. If a
parameter is passed into the method, the field is set.

Fields can be made up and used on the fly; I don't care what you call
them.

=head1 METHODS

=over 4

=item new

Returns a new object of this class. Optionally, you can pass in named
parameters that specify the values of any fields in the class.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $this=bless ({@_}, $class);
	$this->init;
	return $this;
}

=item init

This is called by new(). It's a handy place to set fields, etc, without
having to write your own new() method.

=cut

sub init {}

=item AUTOLOAD

Handles all fields, by creating accessor methods for them the first time
they are accessed.

=cut

sub AUTOLOAD {
	my $field;
	($field = $AUTOLOAD) =~ s/.*://;

	no strict 'refs';
	*$AUTOLOAD = sub {
		my $this=shift;

		return $this->{$field} unless @_;
		return $this->{$field}=shift;
	};
	goto &$AUTOLOAD;
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
