#!/usr/bin/perl -w
#
# Each Element::Line::Boolean is a yes or no question.

package Debian::DebConf::Element::Line::Boolean;
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
		$this->question->template->extended_description."\n");

	my $default=$this->question->value || $this->question->template->default;
	my $prompt;
	if ($default eq 'true') {
		$prompt="Yn";
	}
	elsif ($default eq 'false') {
		$prompt="yN";
	}
	else {
		$prompt="yn";
	}

	my $value='';

	while (1) {
		# Prompt for input.
		$_=$this->frontend->prompt($this->question->template->description.
			" [$prompt] ", $default);
		
		# Handle defaults.
		if ($_ eq '' && defined $default) {
			$value=$default;
			last;
		}

		# Validate the input.
		if (/^y/i) {
			$value='true';
			last;
		}
		elsif (/^n/i) {
			$value='false';
			last;
		}
	}

	$this->question->value($value);
	$this->question->flag_isdefault('false');
	
	$this->frontend->display("\n");
}

1
