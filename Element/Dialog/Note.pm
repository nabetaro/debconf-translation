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

	$this->frontend->showtext('Note', $this->SUPER::show(@_).$this->text);
}

1
