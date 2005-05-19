#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Noninteractive::Progress - dummy progress Element

=cut

package Debconf::Element::Noninteractive::Progress;
use strict;
use base qw(Debconf::Element::Noninteractive);

=head1 DESCRIPTION

This is a dummy progress element.

=cut

sub start {
}

sub set {
}

sub info {
}

sub stop {
}

1;
