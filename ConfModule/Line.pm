#!/usr/bin/perl -w
#
# ConfModule that interfaces to the line-at-a-time FrontEnd.

package ConfModule::Line;
use ConfModule::Base;
use Element::Line::Input;
use Element::Line::Text;
use Element::Line::Note;
use strict;
use vars qw(@ISA);
@ISA=qw(ConfModule::Base);

# Add to the list of elements in our associated FrontEnd.
sub input {
	my $this=shift;
	my $priority=shift;
	my $question=shift;

	push @{$this->frontend->elements},
		Element::Line::Input->new($priority, $question);
	
	return;
}

# Add text to the list of elements.
sub text {
	my $this=shift;
	my $priority=shift;
	my $text=join ' ', @_;
	
	push @{$this->frontend->elements}, 
		Element::Line::Text->new($priority, $text);
	return;
}

# Display a note to the user, which will also make it be saved.
sub note {
	my $this=shift;
	my $priority=shift;
	my $text=join ' ', @_;

	my $note=Element::Line::Note->new($priority, $text);
	$note->frontend($this->frontend);
	$note->ask;
	return;
}

1
