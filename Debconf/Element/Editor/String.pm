#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Editor::String - String question

=cut

package Debconf::Element::Editor::String;
use strict;
use base qw(Debconf::Element);

=head1 DESCRIPTION

This is a string input.

=cut

sub show {
	my $this=shift;

	$this->frontend->comment($this->question->extended_description."\n\n".
		$this->question->description."\n");

	my $default='';
	$default=$this->question->value if defined $this->question->value;

	$this->frontend->item($this->question->name, $default);
}

1
