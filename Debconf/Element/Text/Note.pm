#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Text::Note - A note to the user

=cut

package Debconf::Element::Text::Note;
use strict;
use base qw(Debconf::Element);

=head1 DESCRIPTION

This is a note to the user, presented using a plain text interface.

=cut

sub show {
	my $this=shift;

	$this->frontend->display($this->question->description."\n".
		$this->question->extended_description."\n");

	$this->value('');
}

1
