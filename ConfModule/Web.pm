#!/usr/bin/perl -w
#
# ConfModule that interfaces to the web FrontEnd.

package ConfModule::Web;
use ConfModule::Base;
use Element::Web::Input;
use Element::Web::Text;
use Element::Web::Note;
use strict;
use vars qw(@ISA);
@ISA=qw(ConfModule::Base);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = bless $proto->SUPER::new(@_), $class;
	$self->{capb} = 'backup';
	return $self;					
}

# Add an input item to the list of elements.
sub command_input {
	my $this=shift;
	my $priority=shift;
	my $question=shift;
	push @{$this->frontend->elements},
		Element::Web::Input->new($priority, $question);
	
	return;
}

# Add text to the list of elements.
sub command_text {
	my $this=shift;
	my $priority=shift;
	my $text=join ' ', @_;
	
	push @{$this->frontend->elements}, 
		Element::Web::Text->new($priority, $text);
	return;
}

# Rather than adding a note to the list of elements, we'll display it right
# away, by itself.
sub command_note {
	my $this=shift;
	my $priority=shift;
	my $text=join ' ', @_;

	push @{$this->frontend->elements},
		Element::Web::Note->new($priority, $text);
	return;
}

1
