#!/usr/bin/perl -w
#
# Each Element::Note represents a note to show to the user or log.

package Debian::DebConf::Element::Note;
use strict;
use Debian::DebConf::Element::Text;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element::Text);

# Save the note.
sub show {
	my $this=shift;
	
	# TODO
	
	return "(This information has been saved to your mailbox.)\n\n";
}

1
