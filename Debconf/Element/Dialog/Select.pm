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
		if ($menu_height < 3 && $#choices + 1 >= 2) {
			# Don't display a tiny menu.
			$this->frontend->showtext($this->question->extended_description);
			($text, $lines, $columns)=$this->frontend->sizetext($this->question->description);
			$menu_height=$#choices + 1;
			if ($lines + $#choices + 2 >= $screen_lines) {
				$menu_height = $screen_lines - $lines - 4;
			}
		}
	}
	
	$lines=$lines + $menu_height + $this->frontend->spacer;
	my $c=1;
	foreach (@choices) {
		if ($_ ne $default) {
			push @params, $_, '';
		}
		else {
			# Make the default go first so it is actually
			# selected as the default.
			@params=($_, '', @params);
		}
	}
	
	@params=('--menu', $text, $lines, $columns, $menu_height, @params);

	my $ret=$this->frontend->showdialog(@params);
	return unless defined $ret;
	return $this->translate_to_C($ret);
}

1
