#!/usr/bin/perl -w
#
# Each Element::Dialog::Input represents a item that the user needs to
# enter input into.

package Element::Dialog::Input;
use strict;
use Element::Input;
use ConfigDb;
use vars qw(@ISA);
@ISA=qw(Element::Input);

# Display the element, prompt the user for input.
sub show {
	my $this=shift;

	# Get the question that is bound to this element.
	my $question=ConfigDb::getquestion($this->{question});

	# Figure out how much space in the dialog box the prompt will take.
	my ($text, $lines, $columns)=$this->frontend->sizetext(
		$question->template->extended_description);

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
		@params=('--menu', $text, $lines, $columns, $menu_height);
		my $c=0;
		foreach (@choices) {
			push @params, $c++, $_;
		}
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
