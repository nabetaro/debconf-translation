#!/usr/bin/perl -w

package Debian::DebConf::Element::Line::Note;
use strict;
use Debian::DebConf::Element::Note;
use Debian::DebConf::ConfigDb;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element::Note);

# Display the note and save it.
sub show {
	my $this=shift;

	$this->frontend->display($this->SUPER::show(@_).$this->text);
}

1
