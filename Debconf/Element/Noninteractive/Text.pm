#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Noninteractive::Text - dummy text Element

=cut

package Debconf::Element::Noninteractive::Text;
use strict;
use base qw(Debconf::Element::Noninteractive);

=head1 DESCRIPTION

This is a dummy text element.

=cut

sub show {
	my $this=shift;

	$this->value('');
}

1
