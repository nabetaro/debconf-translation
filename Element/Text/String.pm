#!/usr/bin/perl -w
#
# Each Element::Line::String is a text input field.

package Debian::DebConf::Element::Line::String;
use strict;
use Debian::DebConf::Element::Base;
use Debian::DebConf::ConfigDb;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element::Base);

# Display the element, prompt the user for input.
sub show {
	my $this=shift;

	# Display the question's long desc first.
	$this->frontend->display(
		$this->question->extended_description."\n");
	
	my $default=$this->question->value || $this->question->default;
	
	# Prompt for input using the short description.
	$_=$this->frontend->prompt($this->question->description." ",
		$default);
	
	# Handle defaults.
	if ($_ eq '' && defined $default) {
		$_=$default;
	}

	$this->question->value($_);
	$this->question->flag_isdefault('false');
	
	$this->frontend->display("\n");
}

1
