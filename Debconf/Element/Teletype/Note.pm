#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Teletype::Note - A note to the user

=cut

package Debconf::Element::Teletype::Note;
use strict;
use base qw(Debconf::Element);

=head1 DESCRIPTION

This is a note to the user, presented using a teletype.

=cut

=item show

Notes are not shown in terse mode.

=cut

sub visible {
        my $this=shift;

	return (Debconf::Config->terse eq 'false');
}

sub show {
	my $this=shift;

	$this->frontend->display($this->question->description."\n\n".
		$this->question->extended_description."\n");

	$this->value('');
}

1
