#!/usr/bin/perl -w
#
# Each Element::Web:Text represents a peice of text to display to the user.

package Debian::DebConf::Element::Web::Text;
use strict;
use Debian::DebConf::Element::Text;
use Debian::DebConf::ConfigDb;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element::Text);

# Just generates and returns some html.
sub show {
	my $this=shift;

	$_=$this->text;
	s/\n/\n<br>\n/g;
	return $_."\n<p>\n";
}

1
