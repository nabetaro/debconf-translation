#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Line::Select - select from a list of values

=cut

=head1 DESCRIPTION

This lets the user pick from a number of values, using a plain text interface.

=cut

package Debian::DebConf::Element::Line::Select;
use strict;
use Debian::DebConf::Element::Base;
use Debian::DebConf::ConfigDb;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element::Base);

sub show {
	my $this=shift;
	my %selectindfromlet = ();

	# Display the question's long desc first.
	$this->frontend->display($this->question->extended_description."\n");
	
	my $prompt;
	my $type=$this->question->type;
	my $default=$this->question->value;
	my $pdefault='';
	my @choices=@{$this->question->choices};

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

	my $value='';

	while (1) {
		# Prompt for input.
		$_=$this->frontend->prompt($this->question->description.
			" [$prompt] ", $pdefault);
		
		# Handle defaults.
		if ($_ eq '' && defined $default) {
			$value=$default;
			last;
		}

		my @choices=@{$this->question->choices};
		if (defined $selectindfromlet{$_}) {
			$value=$choices[$selectindfromlet{$_}]; 
			last;
		}
	}

	$this->question->value($value);
	$this->question->flag_isdefault('false');
	
	$this->frontend->display("\n");
}

1
