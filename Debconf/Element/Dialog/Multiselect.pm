#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Dialog::Multiselect - a check list in a dialog box

=cut

package Debconf::Element::Dialog::Multiselect;
use strict;
use base qw(Debconf::Element::Multiselect);
use Debconf::Encoding qw(width);

=head1 DESCRIPTION

This is an input element that can display a dialog box with a check list in
it.

=cut

sub show {
	my $this=shift;
	
	# Figure out how much space in the dialog box the prompt will take.
	# The -2 tells makeprompt to leave at least two lines to use to
	# display the list.
	my ($text, $lines, $columns)=
		$this->frontend->makeprompt($this->question, -2);

	my $screen_lines=$this->frontend->screenheight - $this->frontend->spacer;
	my @params=();
	my @choices=$this->question->choices_split;
	my %value = map { $_ => 1 } $this->translate_default;

	# Figure out how many lines of the screen should be used to
	# scroll the list. Look at how much free screen real estate
	# we have after putting the description at the top. If there's
	# too little, the list will need to scroll.
	my $menu_height=$#choices + 1;
	if ($lines + $#choices + 2 >= $screen_lines) {
		$menu_height = $screen_lines - $lines - 4;
		if ($menu_height < 3 && $#choices + 1 > 2) {
			# Don't display a tiny menu.
			$this->frontend->showtext($this->question, $this->question->extended_description);
			($text, $lines, $columns)=$this->frontend->sizetext($this->question->description);
			$menu_height=$#choices + 1;
			if ($lines + $#choices + 2 >= $screen_lines) {
				$menu_height = $screen_lines - $lines - 4;
			}
		}
	}
	
	$lines=$lines + $menu_height + $this->frontend->spacer;
	my $selectspacer = $this->frontend->selectspacer;
	my $c=1;
	foreach (@choices) {
		push @params, ($_, "");
		push @params, ($value{$_} ? 'on' : 'off');

		# Choices wider than the description text? (Only needed for
		# whiptail BTW.)
		if ($columns < width($_) + $selectspacer) {
			$columns = width($_) + $selectspacer;
		}
	}
	
	if ($this->frontend->dashsep) {
		unshift @params, $this->frontend->dashsep;
	}
	
	@params=('--separate-output', '--checklist', 
	         $text, $lines, $columns, $menu_height, @params);

	my $value=$this->frontend->showdialog($this->question, @params);

	if (defined $value) {
		# Dialog returns the selected items, each on a line.
		# Translate back to C, and turn into our internal format.
		$this->value(join(", ", $this->order_values(
					map { $this->translate_to_C($_) }
					split(/\n/, $value))));
	}
	else {
		my $default='';
		$default=$this->question->value
			if defined $this->question->value;
		$this->value($default);
	}
}

1
