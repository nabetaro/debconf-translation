#!/usr/bin/perl -w

package Element::Web::Note;
use strict;
use Element::Note;
use ConfigDb;
use vars qw(@ISA);
@ISA=qw(Element::Note);

# Save the note and return some html containing it.
sub show {
	my $this=shift;

	$_=$this->SUPER::show(@_).$this->text;
	s/\n/\n<br>\n/g;
	$_.="\n<p>\n";
}

1
