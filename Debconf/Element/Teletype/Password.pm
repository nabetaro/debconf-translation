#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Teletype::Password - password input field

=cut

package Debconf::Element::Teletype::Password;
use strict;
use base qw(Debconf::Element);

=head1 DESCRIPTION

This is a password input field.

=head1 show

Prompts for a password, without displaying it or echoing keystrokes.

=cut

sub show {
	my $this=shift;

	# Display the question's long desc first.
	$this->frontend->display(
		$this->question->extended_description."\n");
	
	my $default='';
	$default=$this->question->value if defined $this->question->value;

	my $value=$this->frontend->prompt_password(
		prompt => $this->question->description,
		default => $default,
		question => $this->question,
	);
	return unless defined $value;

	# Handle defaults.
	if ($value eq '') {
		$value=$default;
	}
	
	$this->frontend->display("\n");
	$this->value($value);
}

1
