#!/usr/bin/perl -w
#
# Each Element::Web:Text represents a peice of text to display to the user.

package Element::Web::Text;
use strict;
use Element::Text;
use ConfigDb;
use vars qw(@ISA);
@ISA=qw(Element::Text);

# Just generates and returns some html.
sub show {
	my $this=shift;

	$_=$this->text;
	s/\n/\n<br>\n/g;
	return $_."\n<p>\n";
}

1
