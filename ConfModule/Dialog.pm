#!/usr/bin/perl -w
#
# ConfModule that interfaces to the dialog FrontEnd.

package Debian::DebConf::ConfModule::Dialog;
use Debian::DebConf::ConfModule::Base;
use Debian::DebConf::Element::Dialog::Input;
use Debian::DebConf::Element::Dialog::Text;
use Debian::DebConf::Element::Dialog::Note;
use strict;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::ConfModule::Base);

# Add to the list of elements.
sub command_input {
	my $this=shift;
	my $priority=shift;
	my $question=shift;

	push @{$this->frontend->elements},
		Debian::DebConf::Element::Dialog::Input->new($priority, $question);
	
	return;
}

# Add text to the list of elements.
sub command_text {
	my $this=shift;
	my $priority=shift;
	my $text=join ' ', @_;
	
	push @{$this->frontend->elements}, 
		Debian::DebConf::Element::Dialog::Text->new($priority, $text);
	return;
}

# Display a note to the user, which will also make it be saved.
sub command_note {
	my $this=shift;
	my $priority=shift;
	my $text=join ' ', @_;

	my $note=Debian::DebConf::Element::Dialog::Note->new($priority, $text);
	$note->frontend($this->frontend);
	$note->show;
	return;
}

1
