#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Dialog::String - A text input field in a dialog box

=cut

package Debconf::Element::Dialog::String;
use strict;
use base qw(Debconf::Element);

=head1 DESCRIPTION

This is an input element that can display a dialog box with a text input
field on it.

=cut

sub show {
	my $this=shift;

	my ($text, $lines, $columns)=
		$this->frontend->makeprompt($this->question);	

	my $default='';
	$default=$this->question->value if defined $this->question->value;

	my @params=('--inputbox', $text, 
		$lines + $this->frontend->spacer, 
		$columns, $default);

	my $value=$this->frontend->showdialog(@params);
	$value='' unless defined $value;
	$this->value($value);
}

1
