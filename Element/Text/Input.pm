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
	my %selectindfromlet = ();

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

		my $uniquelet = 1;
		my %selectletfromind;

		%selectindfromlet = ();

		foreach (0..$#choices) {
			my $let = lc substr($choices[$_], 0, 1);
			$uniquelet = 0 if (defined $selectindfromlet{$let});
			$selectindfromlet{$let}=$_;
		}
		if (!$uniquelet) {
			%selectindfromlet = ();
		foreach (0..$#choices) {
				$selectindfromlet{chr(97 + $_)} = $_;
			}
		}
		%selectletfromind = reverse %selectindfromlet;
		foreach (0..$#choices) {
			$this->frontend->display_nowrap("\t".lc $selectletfromind{$_}.". $choices[$_]");
			if ($choices[$_] eq $default) {
				$prompt .= uc $selectletfromind{$_};
			} else {
				$prompt .= lc $selectletfromind{$_};
			}
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
			if (defined $selectindfromlet{$_}) {
				$value=$choices[$selectindfromlet{$_}]; 
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
