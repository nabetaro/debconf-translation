#!/usr/bin/perl -w
#
# Each Element::Dialog:Text represents a peice of text to display to the user.

package Element::Dialog::Text;
use strict;
use Element::Text;
use ConfigDb;
use vars qw(@ISA);
@ISA=qw(Element::Text);

# Display the text in a dialog box.
sub ask {
	my $this=shift;
	
	system "whiptail", "--backtitle", "Debian Configuration", 
	       "--title", $this->frontend->title || "Note", "--msgbox", 
	       $this->text, 16, 78; # TODO: auto-calc geometry.
}

1
