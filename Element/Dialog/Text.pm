#!/usr/bin/perl -w
#
# Each Element::Dialog::Text is a scrap of text to show to the user.

package Debian::DebConf::Element::Dialog::Text;
use strict;
use Debian::DebConf::Element::Base;
use Debian::DebConf::ConfigDb;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element::Base);

# Display the element, prompt the user for input.
sub show {
	my $this=shift;

	$this->frontend->showtext($this->question->description,
		, $this->question->extended_description);
	$this->question->flag_isdefault('false');
}

1
