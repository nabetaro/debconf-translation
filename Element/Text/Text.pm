#!/usr/bin/perl -w
#
# Each Element::Line::Text represents a peice of text to display to the user.

package Element::Line::Text;
use strict;
use Element::Text;
use ConfigDb;
use Text::Wrap;
use vars qw(@ISA);
@ISA=qw(Element::Text);

# Display the text.
sub ask {
	my $this=shift;

	$this->frontend->ui_display("\n".wrap('','',$this->text)."\n\n");
}

1
