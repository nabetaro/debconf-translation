#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Teletype::Select - select from a list of values

=cut

package Debconf::Element::Teletype::Select;
use strict;
use Debconf::Config;
use POSIX qw(ceil);
use base qw(Debconf::Element::Select);

=head1 DESCRIPTION

This lets the user pick from a number of values.

=head1 METHODS

=over 4

=item expandabbrev

Pass this method what the user entered, followed by the list of choices.
It will try to intuit which one they picked. User can enter the number of
an item in the list, or a unique anchored substring of its name (or the
full name). If they do, the function returns the choice they selected. 
If not, it returns the null string.

=cut

sub expandabbrev {
	my $this=shift;
	my $input=shift;
	my @choices=@_;

	# Check for (valid) numbers, unless in terse mode, when they were
	# never shown any numbers to pick from.
	if (Debconf::Config->terse eq 'false' and 
	    $input=~m/^[0-9]+$/ and $input ne '0' and $input <= @choices) {
		return $choices[$input - 1];
	}
	
	# Check for substrings.
	my @matches=();
	foreach (@choices) {
		return $_ if /^\Q$input\E$/;
		push @matches, $_ if /^\Q$input\E/;
	}
	return $matches[0] if @matches == 1;

	if (! @matches) {
		# Check again, ignoring case.
		foreach (@choices) {
			return $_ if /^\Q$input\E$/i;
			push @matches, $_ if /^\Q$input\E/i;
		}
		return $matches[0] if @matches == 1;
	}
	
	return '';
}

=item printlist

Pass a list of all the choices the user has to choose from. Formats and 
displays the list, using multiple columns if necessary.

=cut

sub printlist {
	my $this=shift;
	my @choices=@_;
	my $width=$this->frontend->screenwidth;

	# Figure out the upper bound on the number of columns.
	my $choice_min=length $choices[0];
	map { $choice_min = length $_ if length $_ < $choice_min } @choices;
	my $max_cols=int($width / (2 + length(@choices) +  2 + $choice_min)) - 1;
	$max_cols = $#choices if $max_cols > $#choices;

	my $max_lines;
	my $num_cols;
COLUMN:	for ($num_cols = $max_cols; $num_cols >= 0; $num_cols--) {
		my @col_width;
		my $total_width;

		$max_lines=ceil(($#choices + 1) / ($num_cols + 1));

		# The last choice should end up in the last column, or there
		# are still too many columns.
		next if ceil(($#choices + 1) / $max_lines) - 1 < $num_cols;

		foreach (my $choice=1; $choice <= $#choices + 1; $choice++) {
			my $choice_length=2
				+ length(@choices) + 2
				+ length($choices[$choice - 1]);
			my $current_col=ceil($choice / $max_lines) - 1;
			if (! defined $col_width[$current_col] ||
			    $choice_length > $col_width[$current_col]) {
				$col_width[$current_col]=$choice_length;
				$total_width=0;
				map { $total_width += $_ } @col_width;
				next COLUMN if $total_width > $width;
			}
		}

		last;
	}

	# Finally, generate and print the output.
	my $line=0;
	my $max_len=0;
	my $col=0;
	my @output=();
	for (my $choice=0; $choice <= $#choices; $choice++) {
		$output[$line] .= "  ".($choice+1).". " . $choices[$choice];
		if (length $output[$line] > $max_len) {
			$max_len = length $output[$line];
		}
		if (++$line >= $max_lines) {
			# Pad existing lines, if necessary.
			if ($col++ != $num_cols) {
				for (my $l=0; $l <= $#output; $l++) {
					$output[$l] .= ' ' x ($max_len - length $output[$l]);
				}
			}
	
			$line=0;
			$max_len=0;
		}
	}

	# Remove unnecessary whitespace at ends of lines.
	@output = map { s/\s+$//; $_ } @output;

	map { $this->frontend->display_nowrap($_) } @output;
}

sub show {
	my $this=shift;
	
	my $default=$this->translate_default;
	my @choices=$this->question->choices_split;	
	my @completions=@choices;

	# Print out the question.
	$this->frontend->display($this->question->extended_description."\n");
	
	# Change default to number of default in choices list
	# except in terse mode.
	if (Debconf::Config->terse eq 'false') {
		for (my $choice=0; $choice <= $#choices; $choice++) {
			if ($choices[$choice] eq $default) {
				$default=$choice + 1;
				last;
			}
		}
		
		# Rather expensive, and does nothing in terse mode.
		$this->printlist(@choices);
		$this->frontend->display("\n");

		# Add choice numbers to completion list in terse mode.
		push @completions, 1..@choices;
	}

	# Prompt until a valid answer is entered.
	my $value;
	while (1) {
		$value=$this->frontend->prompt(
			prompt => $this->question->description,
			default => $default ? $default : '',
			completions => [@completions],
			question => $this->question,
		);
		return unless defined $value;
		$value=$this->expandabbrev($value, @choices);
		last if $value ne '';
	}
	$this->frontend->display("\n");
	$this->value($this->translate_to_C($value));
}

=back

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
