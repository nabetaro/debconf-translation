#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Text::Multiselect - select multiple items

=cut

package Debconf::Element::Text::Multiselect;
use strict;
use Debconf::Gettext;
use base qw(Debconf::Element::Multiselect Debconf::Element::Text::Select);

=head1 DESCRIPTION

This lets the user select multiple items from a list of values, using a plain
text interface. (This is hard to do in plain text, and the UI I have made isn't
very intuitive. Better UI designs welcomed.)

=cut

sub show {
	my $this=shift;

	my @selected;
	my $none_of_the_above=gettext("none of the above");

	my @choices=$this->question->choices_split;
	my %value = map { $_ => 1 } $this->translate_default;
	if ($this->frontend->promptdefault && $this->question->value ne '') {
		push @choices, $none_of_the_above;
	}
	
	# Print out the question.
	$this->frontend->display($this->question->extended_description."\n");
	$this->printlist(@choices);
	$this->frontend->display("\n(".gettext("Type in the letters of the items you want to select, separated by spaces.").")\n");

	# Prompt until a valid answer is entered.
	my $i=1;
	my %choicenum=map { $_ => $i++ } @choices;
	while (1) {
		$_=$this->frontend->prompt(
			prompt => $this->question->description,
		 	default => join(" ", map { $choicenum{$_} }
			                     grep { $value{$_} } @choices),
			completions => [@choices, 1..@choices],
			completion_append_character => " ",
		);
		return unless defined $_;

		# Split up what they entered. They can separate items
		# with whitespace or commas.
		# TODO: i18n
		@selected=split(/[	 ,]+/, $_);

		# Expand what they entered.
		@selected=map { $this->expandabbrev($_, @choices) } @selected;

		# Test to make sure everything they entered expanded ok.
		# If not loop.
		next if grep { $_ eq '' } @selected;

		# Make sure that they didn't select "none of the above"
		# along with some other item. That's undefined, so don't
		# accept it.
		if ($#selected > 0) {
			map { next if $_ eq $none_of_the_above } @selected;
		}
		
		last;
	}

	$this->frontend->display("\n");

	if (defined $selected[0] && $selected[0] eq $none_of_the_above) {
		$this->value('');
	}
	else {
		# Make sure that no item was entered twice. If so, remove
		# the duplicate.
		my %selected=map { $_ => 1 } @selected;

		# Translate back to C locale, and join the list.
		$this->value(join(', ', sort map { $this->translate_to_C($_) }
		                       keys %selected));
	}
}

1
