#!/usr/bin/perl -w

package Element::Line::Note;
use strict;
use Element::Note;
use ConfigDb;
use vars qw(@ISA);
@ISA=qw(Element::Note);

# Display the note and save it.
sub show {
	my $this=shift;

	$this->frontend->display($this->text.$this->SUPER::show(@_));
}

1
