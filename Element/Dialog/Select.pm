#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Dialog::Select - A list of choices in a dialog box

=cut

=head1 DESCRIPTION

This is an input element that can display a dialog box with a list of choices
on it.

=cut

package Debian::DebConf::Element::Dialog::Select;
use strict;
use Debian::DebConf::Element::Base;
use Debian::DebConf::ConfigDb;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element::Base);

sub show {
	my $this=shift;

	# Figure out how much space in the dialog box the prompt will take.
	my ($text, $lines, $columns)=$this->frontend->sizetext(
		$this->question->extended_description."\n\n".
		$this->question->description
	);

	# If it is more than will fit on the screen, just display the prompt
	# first in a series of message boxes.
        if ($lines > ($ENV{LINES} || 25) - 2) {
		$this->frontend->showtext($text);
		$text='';
		$lines=6;
	}

	my $default=$this->question->value;
	my @params=();
	my @choices=@{$this->question->choices};
		
	# Figure out how many lines of the screen should be used to
	# scroll the list. Look at how much free screen real estate
	# we have after putting the description at the top. If there's
	# too little, the list will need to scroll.
	my $menu_height=$#choices + 1;
	my $screen_lines=($ENV{COLUMNS} || 80) - $this->frontend->borderwidth;
	if ($lines + $#choices + 1 > $screen_lines) {
		$menu_height = $screen_lines - $lines;
	}
	$lines=$lines + $menu_height + $this->frontend->spacer;
	my $c=0;
	foreach (@choices) {
		if ($_ ne $default) {
			push @params, $c++, $_
		}
		else {
			# Make the default go first so it is actually
			# selected as the default.
			@params=($c++, $_, @params);
		}
	}
	@params=('--menu', $text, $lines, $columns, $menu_height, @params);

	my ($ret, $value)=$this->frontend->showdialog(@params);

	@choices=@{$this->question->choices};
	$value=$choices[$value];

	$this->question->value($value);
	$this->question->flag_isdefault('false');
}

1
