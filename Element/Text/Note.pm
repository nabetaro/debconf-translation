#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Text::Note - A note to the user

=cut

package Debian::DebConf::Element::Text::Note;
use strict;
use Debian::DebConf::Element; # perlbug
use base qw(Debian::DebConf::Element);

=head1 DESCRIPTION

This is a note to the user, presented using a plain text interface.

=cut

sub show {
	my $this=shift;

	$this->frontend->display($this->question->description."\n".
		$this->question->extended_description."\n");

	return '';
}

1
