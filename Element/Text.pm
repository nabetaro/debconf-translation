#!/usr/bin/perl -w
#
# Each Element::Text represents a peice of text to display to the user.

package Element::Text;
use strict;
use Element::Base;
use vars qw(@ISA);
@ISA=qw(Element::Base);

# Accept two parameters, priority and text.
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = bless $proto->SUPER::new(), $class;
	$self->{priority} = shift;
	$self->{text} = shift;
	return $self;
}

1
