#!/usr/bin/perl -w
#
# Base frontend.

package FrontEnd::Base;
use Priority;
use strict;
use vars qw($AUTOLOAD);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless ($self, $class);
	return $self
}

# This is called when it is time for the frontend to display questions.
sub go {
	my $this=shift;
	
	foreach my $elt (@{$this->{elements}}) {
		next unless Priority::high_enough($elt->priority);
		# Some elements use helper functions in the frontend
		# so thet need to know what frontend to use.
		$elt->frontend($this);
		$elt->ask;
	}
	$this->{elements}=[];
}

# Set/get property.
sub AUTOLOAD {
	my $this=shift;
	my $property = $AUTOLOAD;
	$property =~ s|.*:||; # strip fully-qualified portion
			
	$this->{$property}=shift if @_;
	return $this->{$property};
}

1
