#!/usr/bin/perl -w
#
# Each Element::Web::String is a text box.

package Debian::DebConf::Element::Web::String;
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

	my $default=$this->question->value || $this->question->default;
	my $id=$this->id;
	$_.="<b>".$this->question->description."</b><input name=\"$id\" value=\"$default\">\n";

	return $_;
}

# This gets called once the user has entered a value. It's passed the
# value they entered.
sub set {
	my $this=shift;
	my $value=shift;

	$this->question->value($value);
	$this->question->flag_isdefault('false');
}

1
