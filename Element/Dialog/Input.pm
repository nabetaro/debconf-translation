#!/usr/bin/perl -w
#
# Each Element::Dialog::Input represents a item that the user needs to
# enter input into.

package Debian::DebConf::Element::Dialog::Input;
use strict;
use Debian::DebConf::Element::Input;
use Debian::DebConf::ConfigDb;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element::Input);

# Display the element, prompt the user for input.
sub show {
	my $this=shift;

	# Get the question that is bound to this element.
	my $question=Debian::DebConf::ConfigDb::getquestion($this->{question});

	# Figure out how much space in the dialog box the prompt will take.
	my ($text, $lines, $columns)=$this->frontend->sizetext(
		$question->template->extended_description,
		$question->template->description);

	# If it is more than will fit on the screen, just display the prompt first
	# in a series of message boxes.
        if ($lines > ($ENV{LINES} || 25) - 2) {
		$this->frontend->showtext($question->template->description, $text);
		$text='';
		$lines=6;
	}

	# How dialog is called depends on what type of question this is.
	my $type=$question->template->type;
	my $default=$question->value || $question->template->default;
	my @params=();
	if ($type eq 'boolean') {
		@params=('--yesno', $text, $lines, $columns);
		if ($default eq 'false') {
			push @params, '--defaultno';
		}
	}
	elsif ($type eq 'select') {
		my @choices=@{$question->template->choices};
		
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
	}
	elsif ($type eq 'text') {
		@params=('--inputbox', $text, 
			$lines + $this->frontend->spacer, 
			$columns, $default);
	}
	else {
		die "Unsupported data type \"$type\"";
	}

	my ($ret, $value)=$this->frontend->show_dialog(
		$question->template->description, @params);

	if ($type eq 'boolean') {
		$value=($ret eq 0 ? 'true' : 'false');
	}
	elsif ($type eq 'select') {
		my @choices=@{$question->template->choices};
		$value=$choices[$value];
	}

	$question->value($value);
}

1
