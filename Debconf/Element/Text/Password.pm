#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Text::Password - password input field

=cut

package Debconf::Element::Text::Password;
use strict;
use base qw(Debconf::Element);

=head1 DESCRIPTION

This is a password input field, presented to the user using a plain text
interface.

=cut

sub show {
	my $this=shift;

	# Display the question's long desc first.
	$this->frontend->display(
		$this->question->extended_description."\n");
	
	my $default='';
	$default=$this->question->value if defined $this->question->value;

	# Turn off completion, since it is a stupid thing to do when entering
	# a password.
	$this->frontend->readline->Attribs->{completion_entry_function} = sub {
		my $text=shift;
		my $state=shift;

		return '' if $state == 0;
		return;
	};
	# Don't add trailing spaces after completion.
	$this->frontend->readline->Attribs->{completion_append_character} = '';

	# Prompt for input using the short description.
	my $value=$this->frontend->prompt_password($this->question->description." ", $default,
		sub { $this->complete(@_) });
	return unless defined $value;

	# Handle defaults.
	if ($value eq '') {
		$value=$default;
	}
	
	$this->frontend->display("\n");
	$this->value($value);
}

1
