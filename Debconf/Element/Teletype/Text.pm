#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Teletype::Text - show text to the user

=cut

package Debconf::Element::Teletype::Text;
use strict;
use base qw(Debconf::Element);

=head1 DESCRIPTION

This is a piece of text to output to the user.

=cut

sub show {
	my $this=shift;

	$this->frontend->display($this->question->description."\n\n".
		$this->question->extended_description."\n");

	$this->value('');
}

1
