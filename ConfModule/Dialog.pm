#!/usr/bin/perl -w
#
# ConfModule that interfaces to the dialog FrontEnd.

package ConfModule::Dialog;
use ConfModule::Base;
use Element::Dialog::Input;
use Element::Dialog::Text;
use Element::Dialog::Note;
use strict;
use vars qw(@ISA);
@ISA=qw(ConfModule::Base);

# Add to the list of elements.
sub command_input {
	my $this=shift;
	my $priority=shift;
	my $question=shift;

	push @{$this->frontend->elements},
		Element::Dialog::Input->new($priority, $question);
	
	return;
}

# Add text to the list of elements.
sub command_text {
	my $this=shift;
	my $priority=shift;
	my $text=join ' ', @_;
	
	push @{$this->frontend->elements}, 
		Element::Dialog::Text->new($priority, $text);
	return;
}

# Display a note to the user, which will also make it be saved.
sub command_note {
	my $this=shift;
	my $priority=shift;
	my $text=join ' ', @_;

	my $note=Element::Dialog::Note->new($priority, $text);
	$note->frontend($this->frontend);
	$note->ask;
	return;
}

1
