#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Base - Debconf base class

=cut

package Debian::DebConf::Base;
use strict;
use vars qw($AUTOLOAD);

=head1 DESCRIPTION

Objects of this class may have any number of properties. These properties can
be read by calling the method with the same name as the property. If a
parameter is passed into the method, the property is set.

Properties can be made up and used on the fly; I don't care what you call
them.

Something similar to this should be a generic perl object in the base perl
distribution, since this is the most simple type of perl object. Until it is,
I'll use this. (Sigh)

=cut

=head2 METHODS

=cut

=head2 new

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

=head2 init

This is called by new(). It's a handy place to set fields, etc, without
having to write your own new() method.

=cut

sub init {}

=head2 *

Set/get a property.

=cut

sub AUTOLOAD {
	my $this=shift;
	my $field = $AUTOLOAD;
	$field =~ s|.*:||; # strip fully-qualified portion
	
	return $this->{$field}=shift if @_;
	return $this->{$field};
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
