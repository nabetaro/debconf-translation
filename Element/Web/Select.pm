#!/usr/bin/perl -w
#
# Each Element::Web::Select is a select box.

package Debian::DebConf::Element::Web::Select;
use strict;
use Debian::DebConf::Element::Base;
use Debian::DebConf::ConfigDb;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element::Base);

# Just generates and returns some html.
sub show {
	my $this=shift;

	$_=$this->question->template->extended_description;
	s/\n/\n<br>\n/g;
	$_.="\n<p>\n";

	my $default=$this->question->value || $this->question->template->default;
	my $id=$this->id;
	$_.="<b>".$this->question->template->description."</b>\n<select name=\"$id\">\n";
	my $c=0;
	foreach my $x (@{$this->question->template->choices}) {
		if ($x ne $default) {
			$_.="<option value=".$c++.">$x\n";
		}
		else {
			$_.="<option value=".$c++." selected>$x\n";
		}
	}
	$_.="</select>\n";
	
	return $_;
}

# This gets called once the user has entered a value. It's passed the
# value they entered.
sub set {
	my $this=shift;
	my $value=shift;

	my @choices=@{$this->question->template->choices};
	$value=$choices[$value];

	$this->question->value($value);
	$this->question->flag_isdefault('false');
}

1
