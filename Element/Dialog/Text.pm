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
sub show {
	my $this=shift;

	# TODO: auto-calc geometry.
	$this->frontend->show_dialog('Note', "--msgbox", $this->text, 16, 75);
}

1
