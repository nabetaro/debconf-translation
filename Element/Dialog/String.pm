#!/usr/bin/perl -w
#
# Each Element::Dialog::String is a text input field.

package Debian::DebConf::Element::Dialog::String;
use strict;
use Debian::DebConf::Element::Base;
use Debian::DebConf::ConfigDb;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element::Base);

# Display the element, prompt the user for input.
sub show {
	my $this=shift;

	# Figure out how much space in the dialog box the prompt will take.
	my ($text, $lines, $columns)=$this->frontend->sizetext(
		$this->question->description,
		$this->question->extended_description);

	# If it is more than will fit on the screen, just display the prompt first
	# in a series of message boxes.
        if ($lines > ($ENV{LINES} || 25) - 2) {
		$this->frontend->showtext($this->question->description, $text);
		$text='';
		$lines=6;
	}

	my $default=$this->question->value || $this->question->default;
	my @params=('--inputbox', $text, 
		$lines + $this->frontend->spacer, 
		$columns, $default);

	my ($ret, $value)=$this->frontend->showdialog(
		$this->question->description, @params);

	$this->question->value($value);
	$this->question->flag_isdefault('false');
}

1
