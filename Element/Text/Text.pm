#!/usr/bin/perl -w
#
# Each Element::Line::Text is peice of text to show.

package Debian::DebConf::Element::Line::Text;
use strict;
use Debian::DebConf::Element::Base;
use Debian::DebConf::ConfigDb;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element::Base);

# Display the element.
sub show {
	my $this=shift;

	$this->frontend->display($this->question->template->description."\n".
		$this->question->template->extended_description."\n");

	$this->question->flag_isdefault('false');
}

1
