#!/usr/bin/perl -w

=head1 NAME

Debconf::Sigil - Base sigil class

=cut

package Debconf::Sigil;
use strict;

=head1 DESCRIPTION

This is a little class that implements sigil objects, that are used to indicate
debconf question priorities.

=head1 METHODS

=over 4

=item new

Returns a new oject of the class.

=cut

sub new {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $this=bless ({@_}, $class);
	return $this;
}

=item get

Returns a sigil. Pass in the priority.

In this base class, it just trturns an empty string.

=cut

sub get {
	my $this=shift;
	my $priority=shift;

	return ""
}

=back

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
