#!/usr/bin/perl -w
#
# Each Element::Line::Text represents a peice of text to display to the user.

package Element::Line::Text;
use strict;
use Element::Text;
use ConfigDb;
use vars qw(@ISA);
@ISA=qw(Element::Text);

# Display the text.
sub show {
	my $this=shift;

	$this->frontend->display($this->text."\n\n");
}

1
