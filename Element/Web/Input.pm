#!/usr/bin/perl -w
#
# Each Element::Web::Input represents a item that the user needs to
# enter input into.

package Debian::DebConf::Element::Web::Input;
use strict;
use Debian::DebConf::Element::Input;
use Debian::DebConf::ConfigDb;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element::Input);

# Just generates and returns some html.
sub show {
	my $this=shift;

	# Get the question that is bound to this element.
	my $question=Debian::DebConf::ConfigDb::getquestion($this->{question});

	$_=$question->template->extended_description;
	s/\n/\n<br>\n/g;
	$_.="\n<p>\n";

	my $type=$question->template->type;
	my $default=$question->value || $question->template->default;
	my $id=$this->id;
	if ($type eq 'boolean') {
		$_.="<input type=checkbox name=\"$id\"". ($default eq 'true' ? ' checked' : ''). ">\n".
			$question->template->description;
	}
	elsif ($type eq 'select') {
		$_.=$question->template->description."\n<select name=\"$id\">\n";
		my $c=0;
		foreach my $x (@{$question->template->choices}) {
			if ($x ne $default) {
				$_.="<option value=".$c++.">$x\n";
			}
			else {
				$_.="<option value=".$c++." selected>$x\n";
			}
		}
		$_.="</select>\n";
	}
	elsif ($type eq 'text') {
		$_.=$question->template->description."<input name=\"$id\" value=\"$default\">\n";
	}
	else {
		die "Unsupported data type \"$type\"";
	}
	
	return $_;
}

# This gets called once the user has entered a value. It's passed the
# value they entered.
sub set {
	my $this=shift;
	my $value=shift;

	# Get the question that is bound to this element.
	my $question=Debian::DebConf::ConfigDb::getquestion($this->{question});

	my $type=$question->template->type;
	if ($type eq 'boolean') {
		$value=($value eq 'on' ? 'true' : 'false');
	}
	elsif ($type eq 'select') {
		my @choices=@{$question->template->choices};
		$value=$choices[$value];
	}

	$question->value($value);
}

1
