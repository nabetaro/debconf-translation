#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Text::Multiselect - select multiple items

=cut

=head1 DESCRIPTION

This lets the user select multiple items from a list of values, using a plain
text interface. This is hard to do in plain text, and the UI I have made isn't
very intuitive.

=cut

package Debian::DebConf::Element::Text::Multiselect;
use strict;
use Debian::DebConf::Element;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element);

sub show {
	my $this=shift;

	# Display the question's long desc first.
	$this->frontend->display($this->question->extended_description."\n");
	
	my %selectindfromlet = ();
	my $type=$this->question->type;
	my @choices=$this->question->choices_split;
	my @pdefault=();
	my @selected=();

	# Make a hash of which of the choices are currently selected.
	my %value;
	map { $value{$_} = 1 } $this->question->value_split;

	# Output the list of choices.
	my $uniquelet = 1;
	my %selectletfromind;
	%selectindfromlet = ();
	foreach (0..$#choices) {
		my $let=lc substr($choices[$_], 0, 1);
		$uniquelet = 0 if (defined $selectindfromlet{$let});
		$selectindfromlet{$let}=$_;
	}
	if (!$uniquelet) {
		%selectindfromlet = ();
		foreach (0..$#choices) {
			if ($_ < 26) {
				$selectindfromlet{chr(97 + $_)} = $_;
			}
			else {
				# Nasty fallback, but this happens rarely.
				$selectindfromlet{$_ - 25} = $_;
			}
		}
	}
	%selectletfromind = reverse %selectindfromlet;
	foreach (0..$#choices) {
		if ($value{$choices[$_]}) {
			push @pdefault, $selectletfromind{$_};
		}
		$this->frontend->display_nowrap("\t[$selectletfromind{$_}] $choices[$_]");
		
	}
	$this->frontend->display("\n(Type in the letters of the items you want to select, separated by spaces.)\n");

	my $value='';

	while (1) {
		# Prompt for input.
		$_=$this->frontend->prompt($this->question->description.' ',
		 	join(" ",@pdefault));

		# Split up what they entered. They can separate items
		# with whitespace, commas, etc.
		@selected=split(/[^A-Za-z0-9]*/, $_);

		# Test to make sure everything they entered is a valid choice.
		# If not, loop.
		my $ok=1;
		map { $ok='' unless exists $selectindfromlet{$_} } @selected;
		last if $ok;
	}

	# Now tuen what they entered into the representation we use
	# internally, and save it.
	$this->question->value(join(', ', map { $choices[$selectindfromlet{$_}] } @selected));
	$this->question->flag_isdefault('false');
	
	$this->frontend->display("\n");
}

1
