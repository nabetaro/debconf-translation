#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Dialog::Select - A list of choices in a dialog box

=cut

package Debconf::Element::Dialog::Select;
use strict;
use base qw(Debconf::Element::Select);
use Debconf::Encoding qw(width);

=head1 DESCRIPTION

This is an input element that can display a dialog box with a list of choices
on it.

=cut

sub show {
	my $this=shift;

	# Figure out how much space in the dialog box the prompt will take.
 	# The -2 tells makeprompt to leave at least two lines to use to
 	# display the list.
	my ($text, $lines, $columns)=
		$this->frontend->makeprompt($this->question, -2);

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
		push @params, $_, '';
		
		# Choices wider than the description text? (Only needed for
		# whiptail BTW.)
		if ($columns < width($_) + $selectspacer) {
			$columns = width($_) + $selectspacer;
		}
	}
	
	if ($this->frontend->dashsep) {
		unshift @params, $this->frontend->dashsep;
	}
	
	@params=('--default-item', $default, '--menu', 
		  $text, $lines, $columns, $menu_height, @params);

	my $value=$this->frontend->showdialog($this->question, @params);
	if (defined $value) {
		$this->value($this->translate_to_C($value)) if defined $value;
	}
	else {
		my $default='';
		$default=$this->question->value
			if defined $this->question->value;
		$this->value($default);
	}
}

1
