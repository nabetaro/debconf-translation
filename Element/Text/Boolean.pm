#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Text::Boolean - Yes/No question

=cut

=head1 DESCRIPTION

This is a yes or no question, presented to the user using a plain text
interface.

=cut

package Debian::DebConf::Element::Text::Boolean;
use strict;
use Debian::DebConf::Element;
use Debian::DebConf::ConfigDb;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element);

sub show {
	my $this=shift;

	# Display the question's long desc first.
	$this->frontend->display(
		$this->question->extended_description."\n");

	my $default=$this->question->value;
	my $prompt;
	if ($default eq 'true') {
		$prompt="Yn";
		$default='n';
	}
	elsif ($default eq 'false') {
		$prompt="yN";
		$default='n';
	}
	else {
		$prompt="yn";
	}

	my $value='';

	while (1) {
		# Prompt for input.
		$_=$this->frontend->prompt($this->question->description.
			" [$prompt] ", '');
		
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

	$this->question->value($value);
	$this->question->flag_isdefault('false');
	
	$this->frontend->display("\n");
}

1
