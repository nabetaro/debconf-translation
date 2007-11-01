#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Web::Progress - dummy progress Element

=cut

package Debconf::Element::Web::Progress;
use strict;
use base qw(Debconf::Element);

=head1 DESCRIPTION

This element does nothing. The user gets to wait. :-)

It might be a good idea to produce some kind of "Please wait" web page,
since progress bars are usually created exactly when the process is going to
take a long time.

=cut

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
