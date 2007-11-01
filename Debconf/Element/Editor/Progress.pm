#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Editor::Progress - dummy progress Element

=cut

package Debconf::Element::Editor::Progress;
use strict;
use base qw(Debconf::Element);

=head1 DESCRIPTION

This element does nothing, as progress bars do not make sense in an editor.

=cut

# TODO: perhaps we could at least print progress messages to stdout?

sub start {
}

sub set {
	return 1;
}

sub info {
	return 1;
}

sub stop {
}

1;
