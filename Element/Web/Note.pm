#!/usr/bin/perl -w

package Debian::DebConf::Element::Web::Note;
use strict;
use Debian::DebConf::Element::Note;
use Debian::DebConf::ConfigDb;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element::Note);

# Save the note and return some html containing it.
sub show {
	my $this=shift;

	$_=$this->SUPER::show(@_).$this->text;
	s/\n/\n<br>\n/g;
	$_.="\n<p>\n";
}

1
