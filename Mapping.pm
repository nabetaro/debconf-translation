#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Mapping - Template to Question mapping object

=cut

=head1 DESCRIPTION

This is an object that represents a mapping between a Question and a Template.

Set the template property to the name of the template the Question is mapped to. Set
the question property to the name of the Question.

=cut

package Debian::DebConf::Mapping;
use strict;
use vars qw($AUTOLOAD);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {};
	bless ($self, $class);
	return $self;
}

# Set/get property.
sub AUTOLOAD {
	my $this=shift;
	my $property = $AUTOLOAD;
	$property =~ s|.*:||; # strip fully-qualified portion
	
	$this->{$property}=shift if @_;
	$this->{$property};
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
