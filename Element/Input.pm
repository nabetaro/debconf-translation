#!/usr/bin/perl -w
#
# Each Element::Input represents a item that the user needs to enter input
# into.

package Debian::DebConf::Element::Input;
use strict;
use Debian::DebConf::Element::Base;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element::Base);

# Accept two parameters, priority and question id.
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = bless $proto->SUPER::new(), $class;
	$self->{priority} = shift;
	$self->{question} = shift;
	return $self;
}

1
