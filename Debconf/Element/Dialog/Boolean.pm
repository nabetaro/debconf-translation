#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Dialog::Boolean - Yes/No dialog box

=cut

package Debconf::Element::Dialog::Boolean;
use strict;
use base qw(Debconf::Element);

=head1 DESCRIPTION

This is an input element that can display a dialog box with Yes and No buttons
on it.

=cut

sub show {
	my $this=shift;

	my @params=('--yesno');
	push @params, $this->frontend->dashsep if $this->frontend->dashsep;
	# Note 1 is passed in, because we can squeeze on one more line
	# in a yesno dialog than in other types.
	push @params, $this->frontend->makeprompt($this->question, 1);
	if (defined $this->question->value && $this->question->value eq 'false') {
		# Put it at the start of the option list,
		# where dialog likes it.
		unshift @params, '--defaultno';
	}

	my ($ret, $value)=$this->frontend->showdialog($this->question, @params);
	if (defined $ret) {
		$this->value($ret eq 0 ? 'true' : 'false');
	}
	else {
		my $default='';
		$default=$this->question->value
			if defined $this->question->value;
		$this->value($default);
	}
}

1
