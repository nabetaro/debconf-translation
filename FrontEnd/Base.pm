#!/usr/bin/perl -w
#
# Base frontend.

package Debian::DebConf::FrontEnd::Base;
use Debian::DebConf::Priority;
use Debian::DebConf::Element::Base;
use strict;
use vars qw($AUTOLOAD);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{elements}=[];
	bless ($self, $class);
	return $self
}

# Create an input element. Pass in the question that the element represents.
sub makeelement {
	my $this=shift;
	my $question=shift;

	return Debian::DebConf::Element::Base->new($question);
}

# Add an item to the list of items to display.
sub add {
	my $this=shift;
	my $question=shift || die "\$question is undefined";
	my $priority=shift;

	# Skip items that the user has seen or that are unimportant.
	return unless Debian::DebConf::Priority::high_enough($priority);
	return if $question->flag_isdefault eq 'false';

	# Pass in the frontend to use as well, some elements need it.
	push @{$this->{elements}}, $this->makeelement($question);
}

# This is called when it is time for the frontend to display questions.
sub go {
	my $this=shift;

	map { $_->show} @{$this->{elements}};
	$this->{elements}=[];
	return '';
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
