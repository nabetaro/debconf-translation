#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Dialog::Password - A password input field in a dialog box

=cut

=head1 DESCRIPTION

This is an input element that can display a dialog box with a password input
field on it.

=cut

package Debian::DebConf::Element::Dialog::Password;
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
	my @params=('--inputbox', $text, 
		$lines + $this->frontend->spacer, 
		$columns, $default);

	my ($ret, $value)=$this->frontend->showdialog(@params);
	
	exit $ret if $ret != 0;

	$this->question->value($value);
	$this->question->flag_isdefault('false');
}

1
