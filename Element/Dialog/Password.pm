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
use Debian::DebConf::Element;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element);

sub show {
	my $this=shift;
	
	my ($text, $lines, $columns)=
		$this->frontend->makeprompt($this->question);

	my $default='';
	$default=$this->question->value if defined $this->question->value;
	my @params=('--passwordbox', $text, 
		$lines + $this->frontend->spacer, 
		$columns, $default);

	return $this->frontend->showdialog(@params);
}

1
