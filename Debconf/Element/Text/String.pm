#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Text::String - string input field

=cut

package Debconf::Element::Text::String;
use strict;
use base qw(Debconf::Element);

=head1 DESCRIPTION

This is a string input field, presented to the user using a plain text
interface.

=cut

sub show {
	my $this=shift;

	# Display the question's long desc first.
	$this->frontend->display(
		$this->question->extended_description."\n");

	my $default='';
	$default=$this->question->value if defined $this->question->value;

	# Prompt for input using the short description.
	my $value=$this->frontend->prompt($this->question->description, $default);
	return unless defined $value;
	
	# Handle defaults.
	if ($value eq '') {
		$value=$default;
	}
	
	$this->frontend->display("\n");
	$this->value($value);
}

1
