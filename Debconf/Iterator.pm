#!/usr/bin/perl -w

=head1 NAME

Debconf::Iterator - DebConf iterator object

=cut

package Debconf::Iterator;
use strict;
use base qw(Debconf::Base);

=head1 DESCRIPTION

This is an iterator object, for use by the DbDriver mainly. Use this object
just as you would use anything else derived from Debconf::Base.

=head1 FIELDS

Generally any you want. By convention prefix any field names you use with 
your module's name, to prevent conflicts when multiple modules need to use
the same iterator.

=over 4

=item callback

A subroutine reference, this subroutine will be called each time the
iterator iterates, and should return the next item in the sequence or
undef.

=back

=head1 METHODS

=item iterate

Iterate to and return the next item, or undef when done.

=cut

sub iterate {
	my $this=shift;

	$this->callback->($this);
}

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
