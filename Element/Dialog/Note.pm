#!/usr/bin/perl -w

package Element::Dialog::Note;
use strict;
use Element::Note;
use ConfigDb;
use vars qw(@ISA);
@ISA=qw(Element::Note);

# Display the note and save it.
sub show {
	my $this=shift;

	$this->frontend->show_dialog('Note', "--msgbox",
		$this->frontend->sizetext($this->text.$this->SUPER::show(@_)));
}

1
