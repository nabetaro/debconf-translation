#!/usr/bin/perl -w
#
# Each Element::Dialog::Note is a note to show to the user.

package Debian::DebConf::Element::Dialog::Note;
use strict;
use Debian::DebConf::Element::Base;
use Debian::DebConf::ConfigDb;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element::Base);

# Display the element, prompt the user for input.
sub show {
	my $this=shift;

	$this->frontend->showtext($this->question->template->description,
		, $this->question->template->extended_description);
	$this->question->flag_isdefault('false');
}

1
