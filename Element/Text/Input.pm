#!/usr/bin/perl -w
#
# Each Element::Line::Input represents a item that the user needs to
# enter input into, for use with the simple line-at-a-time frontend.

package Debian::DebConf::Element::Line::Input;
use strict;
use Debian::DebConf::Element::Input;
use Debian::DebConf::ConfigDb;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element::Input);

# Display the element, prompt the user for input.
sub show {
	my $this=shift;

	# Get the question that is bound to this element.
	my $question=Debian::DebConf::ConfigDb::getquestion($this->{question});

	# Display the question's long desc and then the short desc.
	$this->frontend->display($question->template->extended_description."\n");
	
	# How the user is actually prompted depends on what type of question
	# this is.
	my $prompt='';
	my $type=$question->template->type;
	my $default=$question->value || $question->template->default;
	my $pdefault='';
	if ($type eq 'boolean') {
		# Yes or no?
		if ($default eq 'true') {
			$prompt="Yn";
		}
		elsif ($default eq 'false') {
			$prompt="yN";
		}
		else {
			$prompt="yn";
		}
	}
	elsif ($type eq 'select') {
		# Choose one.
		my @choices=@{$question->template->choices};
		# Output the list of choices, at the same time, generate
		# a prompt with the full list in it.
		# TODO: handle more than 26 choices.
		foreach (0..$#choices) {
			$this->frontend->display_nowrap("\t".chr(97 + $_).". $choices[$_]");
			$prompt.=chr($_ + ($choices[$_] eq $default ? 65 : 97));
		}
		$this->frontend->display("\n");
	}
	elsif ($type eq 'text') {
		$pdefault=$default;
	}
	else {
		die "Unsupported data type \"$type\"";
	}

	my $value='';

	while (1) {
		# Prompt for input.
		$_=$this->frontend->prompt($question->template->description." ".
			($prompt ? "[$prompt] " : ''), $pdefault);
		
		# handle defaults.
		if ($_ eq '' && defined $default) {
			$value=$default;
			last;
		}

		# Validate the input.
		if ($type eq 'boolean') {
			if (/^y/i) {
				$value='true';
				last;
			}
			elsif (/^n/i) {
				$value='false';
				last;
			}
		}
		elsif ($type eq 'select') {
			my @choices=@{$question->template->choices};
			if (ord(lc $_) >= 97 && ord(lc $_) <= 97 + $#choices) {
				$value=$choices[ord(lc $_) - 97];
				last;
			}
		}
		elsif ($type eq 'text') {
			$value=$_;
			last;
		}
	}

	$question->value($value);
	
	$this->frontend->display("\n");
}

1
