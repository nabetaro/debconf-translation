#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Text::Boolean - Yes/No question

=cut

package Debian::DebConf::Element::Text::Boolean;
use strict;
use Debian::DebConf::Gettext;
use Debian::DebConf::Element; # perlbug
use base qw(Debian::DebConf::Element);

=head1 DESCRIPTION

This is a yes or no question, presented to the user using a plain text
interface.

=head1 METHODS

=over 4

=cut

sub show {
	my $this=shift;

	# Display the question's long desc first.
	$this->frontend->display($this->question->extended_description."\n");

	my $default='';
	$default=$this->question->value if defined $this->question->value;
	if ($default eq 'true') {
		$default=gettext("yes");
	}
	elsif ($default eq 'false') {
		$default=gettext("no");
	}

	my $value='';

	while (1) {
		# Prompt for input.
		$_=$this->frontend->prompt($this->question->description, $default);
		
		# Handle defaults.
		if ($_ eq '' && defined $default) {
			$_=$default;
		}

		# Validate the input. Check to see if the first letter
		# matches the start of "yes" or "no". Internationalization
		# makes this harder, because there may be some lanage where
		# "yes" and "no" both start with the same letter.
		# Special-case that in too.
		my $y=gettext("yes");
		my $n=gettext("no");
		if ($y ne $n) {
			# When possible, trim to first letters.
			$y=substr($y, 0, 1);
			$n=substr($n, 0, 1);
		}
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
	return $value;
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
