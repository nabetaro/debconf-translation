#!/usr/bin/perl -w
#
# FrontEnd that presents a simple dialog interface, using whiptail (or dialog)
# This inherits from the generic ConfModule and just defines some methods to
# handle commands.

package FrontEnd::Dialog;
use FrontEnd::Base;
use Element::Dialog::Input;
use Element::Dialog::Text;
use Element::Dialog::Note;
use Priority;
use strict;
use vars qw(@ISA);
@ISA=qw(FrontEnd::Base);

$|=1;

############################################
# Communication with the configuation module

sub capb {
	my $this=shift;
	$this->{capb}=[@_];

	# I do know how to back up.
	return "backup";
}

# Add to the list of elements.
sub input {
	my $this=shift;
	my $priority=shift;
	my $question=shift;

	push @{$this->{elements}},
		Element::Dialog::Input->new($priority, $question);
	
	return;
}

# Add text to the list of elements.
sub text {
	my $this=shift;
	my $priority=shift;
	my $text=join ' ', @_;
	
	push @{$this->{elements}}, 
		Element::Dialog::Text->new($priority, $text);
	return;
}

# Display a note to the user, which will also make it be saved.
sub note {
	my $this=shift;
	my $priority=shift;
	my $text=join ' ', @_;

	my $note=Element::Dialog::Note->new($priority, $text);
	$note->frontend($this);
	$note->ask;
	return;
}

1
