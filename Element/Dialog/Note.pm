#!/usr/bin/perl -w

package Element::DIalog::Note;
use strict;
use Element::Note;
use ConfigDb;
use vars qw(@ISA);
@ISA=qw(Element::Note);

# Display the note and save it.
sub show {
	my $this=shift;

	$this->frontend->show_dialog('Note', "--msgbox", $this->text.
		"\n(This information has been saved to your mailbox.)\n", 
		16, 75);

	$this->SUPER::show(@_);
}

1
