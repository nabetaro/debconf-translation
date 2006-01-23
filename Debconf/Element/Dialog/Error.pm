#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Dialog::Error - An error message in a dialog box

=cut

package Debconf::Element::Dialog::Error;
use strict;
use base qw(Debconf::Element);

=head1 DESCRIPTION

This is an input element that can display a dialog box with an error message
on it.

=cut

sub show {
	my $this=shift;

	$this->frontend->showtext($this->question, 
		$this->question->description."\n\n".
		$this->question->extended_description
	);
	$this->value('');
}

1
