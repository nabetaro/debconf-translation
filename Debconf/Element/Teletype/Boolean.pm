#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Teletype::Boolean - Yes/No question

=cut

package Debconf::Element::Teletype::Boolean;
use strict;
use Debconf::Gettext;
use base qw(Debconf::Element);

=head1 DESCRIPTION

This is a yes or no question, presented to the user using a teletype
interface.

=head1 METHODS

=over 4

=cut

sub show {
	my $this=shift;

	my $y=gettext("yes");
	my $n=gettext("no");

	# Display the question's long desc first.
	$this->frontend->display($this->question->extended_description."\n");

	my $default='';
	$default=$this->question->value if defined $this->question->value;
	if ($default eq 'true') {
		$default=$y;
	}
	elsif ($default eq 'false') {
		$default=$n;
	}

	my $value='';

	while (1) {
		# Prompt for input.
		$_=$this->frontend->prompt(
			default => $default,
			completions => [$y, $n],
			prompt => $this->question->description
		);
		return unless defined $_;

		# Handle defaults.
		if ($_ eq '' && length $default) {
			$_=$default;
		}

		# Validate the input. Check to see if the first letter
		# matches the start of "yes" or "no". Internationalization
		# makes this harder, because there may be some language where
		# "yes" and "no" both start with the same letter.
		if (substr($y, 0, 1) ne substr($n, 0, 1)) {
			# When possible, trim to first letters.
			$y=substr($y, 0, 1);
			$n=substr($n, 0, 1);
		}
		# I suppose this would break in a language where $y is a
		# anchored substring of $n. Any such language should be taken
		# out and shot. TODO: I hear Chinese actually needs this..
		# Also, I should just gettext("y") and "n", and use those,
		# rather than taking the first character, may not makse
		# sense in multi-byte encodings.
		if (/^\Q$y\E/i) {
			$value='true';
			last;
		}
		elsif (/^\Q$n\E/i) {
			$value='false';
			last;
		}
	}
	
	$this->frontend->display("\n");
	$this->value($value);
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
