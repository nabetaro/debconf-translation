#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Text::Boolean - Yes/No question

=cut

package Debian::DebConf::Element::Text::Boolean;
use strict;
use Debian::DebConf::Element; # perlbug
use base qw(Debian::DebConf::Element);

=head1 DESCRIPTION

This is a yes or no question, presented to the user using a plain text
interface.

=cut

sub show {
	my $this=shift;

	# Display the question's long desc first.
	$this->frontend->display(
		$this->question->extended_description."\n");

	my $default='';
	$default=$this->question->value if defined $this->question->value;
	if ($default eq 'true') {
		$default='y';
	}
	elsif ($default eq 'false') {
		$default='n';
	}

	my $value='';

	while (1) {
		# Prompt for input.
		$_=$this->frontend->prompt($this->question->description, $default);
		
		# Handle defaults.
		if ($_ eq '' && defined $default) {
			$_=$default;
		}

		# Validate the input.
		if (/^y/i) {
			$value='true';
			last;
		}
		elsif (/^n/i) {
			$value='false';
			last;
		}
	}
	
	$this->frontend->display("\n");
	return $value;
}

1
