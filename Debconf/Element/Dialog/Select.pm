#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Dialog::Select - A list of choices in a dialog box

=cut

package Debconf::Element::Dialog::Select;
use strict;
use base qw(Debconf::Element::Select);

=head1 DESCRIPTION

This is an input element that can display a dialog box with a list of choices
on it.

=cut

sub show {
	my $this=shift;

	# Figure out how much space in the dialog box the prompt will take.
	my ($text, $lines, $columns)=
		$this->frontend->makeprompt($this->question);

	my $screen_lines=$this->frontend->screenheight - $this->frontend->spacer;
	my $default=$this->translate_default;
	my @params=();
	my @choices=$this->question->choices_split;
	
	# Figure out how many lines of the screen should be used to
	# scroll the list. Look at how much free screen real estate
	# we have after putting the description at the top. If there's
	# too little, the list will need to scroll.
	my $menu_height=$#choices + 1;
	if ($lines + $#choices + 2 >= $screen_lines) {
		$menu_height = $screen_lines - $lines - 4;
	}
	
	$lines=$lines + $menu_height + $this->frontend->spacer;
	my $c=1;
	my $selectspacer = $this->frontend->selectspacer;
	foreach (@choices) {
		if ($_ ne $default) {
			push @params, $_, '';
		}
		else {
			# Make the default go first so it is actually
			# selected as the default.
			@params=($_, '', @params);
		}
		# Choices wider than the description text? (Only needed for
		# whiptail BTW.)
		if ($columns < length($_) + $selectspacer) {
			$columns = length($_) + $selectspacer;
		}
	}
	
	if ($this->frontend->dashsep) {
		unshift @params, $this->frontend->dashsep;
	}
	
	@params=('--menu', $text, $lines, $columns, $menu_height, @params);

	my $value=$this->frontend->showdialog($this->question, @params);
	if (defined $value) {
		$this->value($this->translate_to_C($value));
	}
	else {
		$this->value('');
	}
}

1
