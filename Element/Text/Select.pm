#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Text::Select - select from a list of values

=cut

package Debian::DebConf::Element::Text::Select;
use strict;
use POSIX qw(ceil);
use Debian::DebConf::Element::Select; # perlbug
use base qw(Debian::DebConf::Element::Select);

=head1 DESCRIPTION

This lets the user pick from a number of values, using a plain text interface.

=head1 METHODS

=over 4

=item pickabbrevs

This method picks what abbreviations the user should type to select items from
a list. When possible, it uses the first letter of a list item as the
abbreviation. If two items share a letter, it finds and uses an unused letter
instead. If it uses up all letters of the alphabet, it uses numbers for the
rest of the abbreviations. It allows you to mark some items as important; 
it will allocate the best hotkeys to them that it can.

Pass in reference to an array listing the important items, followed by 
an array of all the items. A hash will be returned, with the items as keys
and the abbreviations as values.

=cut

sub pickabbrevs {
	my $this=shift;
	my @important=@{(shift)};
	my @items=@_;

	my %alphabet=map { chr(97 + $_) => 1 } 0..25;
	my %abbrevs;
	
	# First pass -- find hotkeys that match the first character of
	# the item.
	my $count=0;
	foreach my $item (@important, @items) {
		# TODO: i18n
		if (! $abbrevs{$item} && $item =~ m/^([a-z])/i && $alphabet{lc $1}) {
			$abbrevs{$item}=lc $1;
			$alphabet{lc $1}='';
			$count++;
		}
	}
	
	return %abbrevs if $count == @items; # Done; short circuit.
	
	# Second pass -- assign hotkeys to items that don't yet have one,
	# from what's left of the alphabet. If the alphabet is exhausted,
	# start counting up from 1.
	my @alphabits=grep { $alphabet{$_} } keys %alphabet;
	my $counter=1;
	foreach my $item (@items) {
		$abbrevs{$item} = (shift @alphabits || $counter++)
			unless $abbrevs{$item};
	}

	return %abbrevs;
}

=item expandabbrev

Pass this method what the user entered, followed by the hash returned by
pickabbrevs. It will expand the abbreviation they entered and return the
choice that corresponds to it. If they entered an invalid abbreviation,
it returns false.

=cut

sub expandabbrev {
	my $this=shift;
	my $abbrev=lc shift;
	my %values=reverse @_;

	return $values{$abbrev} if exists $values{$abbrev};
	return '';
}

=item printlist

Pass first a reference to an array containing abbreviation info, then a list
of all the choices the user has to choose from. Formats and displays the
list, using multiple columns if necessary.

=cut

sub printlist {
	my $this=shift;
	my %abbrevs=%{(shift)};
	my @choices=@_;
	my $width=$this->frontend->screenwidth;

	# Figure out the upper bound on the number of columns.
	my $choice_min=length $choices[0];
	map { $choice_min = length $_ if length $_ < $choice_min } @choices;
	# (The 5 is 2 leading spaces + 1 char abbrev + 1 period + 1 space.)
	# TODO: handle longer abbrevs.
	my $max_cols=int($width / (5 + $choice_min)) - 1;
	$max_cols = $#choices if $max_cols > $#choices;

	my $max_lines;
	my $num_cols;
COLUMN:	for ($num_cols = $max_cols; $num_cols > 0; $num_cols--) {
		my @col_width;
		my $total_width;

		$max_lines=ceil(($#choices + 1) / ($num_cols + 1));

		# The last choice should end up in the last column, or there
		# are still too many columns.
		next if ceil(($#choices + 1) / $max_lines) - 1 < $num_cols;

		foreach (my $choice=1; $choice <= $#choices + 1; $choice++) {
			my $choice_length=2
				+ length($abbrevs{$choices[$choice - 1]}) + 2
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
	foreach (my $choice=0; $choice <= $#choices; $choice++) {
		$output[$line] .= "  $abbrevs{$choices[$choice]}. " . 
				  $choices[$choice];
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

	map { print "$_\n" } @output;
}

sub show {
	my $this=shift;
	
	my $default=$this->translate_default;
	my @choices=$this->question->choices_split;	

	# Come up with the set of abbreviations to use.
	my @important;
	push @important, $default if $default ne '';
	my %abbrevs=$this->pickabbrevs(\@important, @choices);

	# Print out the question.
	$this->frontend->display($this->question->extended_description."\n");
	$this->printlist(\%abbrevs, @choices);
	$this->frontend->display("\n");

	# Prompt until a valid answer is entered.
	my $value;
	while (1) {
		$value=$this->expandabbrev($this->frontend->prompt(
						$this->question->description,
						$default ne '' ? $abbrevs{$default} : ''),
					   %abbrevs);
		last if $value ne '';
	}
	$this->frontend->display("\n");
	return $this->translate_to_C($value);
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
