#!/usr/bin/perl -w
#
# Each Element::Dialog:Text represents a peice of text to display to the user.

package Debian::DebConf::Element::Dialog::Text;
use strict;
use Debian::DebConf::Element::Text;
use Debian::DebConf::ConfigDb;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element::Text);

# Display the text in a dialog box.
sub show {
	my $this=shift;

	$this->frontend->showtext('Note', $this->text);
}

# Nothing to do.
sub set {}

1
