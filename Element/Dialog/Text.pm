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

	my ($text, $height, $width)=$this->frontend->sizetext($this->text);

	# Test to see if the text is too long to fit on a single dialog
	# and if so, break it up into multiple dialogs.
	my $lines = ($ENV{LINES} || 25);
	if ($height > $lines - 2) {
		my @lines = split(/\n/, $text);
		for (my $c = 0; $c <= $#lines;  $c += $lines - 4 - $this->frontend->borderheight) {
			my $text=join("\n", @lines[$c..($c + $lines - 4 - $this->frontend->borderheight)]);
			$this->frontend->show_dialog('Note'. ($c > 0 ? " (continued)" : ''), "--msgbox",
				$text, scalar split(/\n/, $text) + $this->frontend->borderheight,
				$width);
		}
	}
	else {
		$this->frontend->show_dialog('Note', "--msgbox", 
			$text, $height, $width);
	}
}


1
