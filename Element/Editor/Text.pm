#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Editor::Text - Just test to display to user.

=cut

package Debian::DebConf::Element::Editor::Text;
use strict;
use Debian::DebConf::Element; # perlbug
use base qw(Debian::DebConf::Element);

=head1 DESCRIPTION

This is just some text to display to the user.

=cut

sub show {
	my $this=shift;

	$this->frontend->comment($this->question->extended_description."\n\n".
		$this->question->description."\n\n");
}

1
