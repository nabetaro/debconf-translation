#!/usr/bin/perl -w

package Debian::DebConf::Element::Web::Text;
use strict;
use Debian::DebConf::Element::Base;
use Debian::DebConf::ConfigDb;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element::Base);

# Just generates and returns some html.
sub show {
	my $this=shift;

	$_=$this->question->extended_description;
	s/\n/\n<br>\n/g;
	$_.="\n<p>\n";

	return "<b>".$this->question->description."</b>$_<p>";
}

# The user has now see this text.
sub set {
	my $this=shift;

	$this->question->flag_isdefault('false');
}

1
