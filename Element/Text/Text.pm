#!/usr/bin/perl -w
#
# Each Element::Line::Text represents a peice of text to display to the user.

package Debian::DebConf::Element::Line::Text;
use strict;
use Debian::DebConf::Element::Text;
use Debian::DebConf::ConfigDb;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element::Text);

# Display the text.
sub show {
	my $this=shift;

	$this->frontend->display($this->text."\n\n");
}

1
