#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Dialog::Password - A password input field in a dialog box

=cut

package Debconf::Element::Dialog::Password;
use strict;
use base qw(Debconf::Element);

=head1 DESCRIPTION

This is an input element that can display a dialog box with a password input
field on it.

=cut

sub show {
	my $this=shift;
	
	my ($text, $lines, $columns)=
		$this->frontend->makeprompt($this->question);

	my @params=('--passwordbox');
	push @params, $this->frontend->dashsep if $this->frontend->dashsep;
	push @params, ($text, $lines + $this->frontend->spacer, $columns);
	my $ret=$this->frontend->showdialog($this->question, @params);

	# The password isn't passed in, so if nothing is entered,
	# use the default.
	if (! defined $ret || $ret eq '') {
		my $default='';
		$default=$this->question->value
			if defined $this->question->value;
		$this->value($default);
	}
	else {
		$this->value($ret);
	}
}

1
