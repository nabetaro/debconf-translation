#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Container - Base container input element

=cut

=head1 DESCRIPTION

This is a base Container input element. A Container is an element that can
hold other elements. Containers don't have any display of their own per se.

=cut

=head1 METHODS

=cut

package Debian::DebConf::Element::Select;
use Debian::DebConf::Element;
use strict;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element);

=head2 visible

Containers are visible if any of the items contained in them are visible.
Or are they? This is still being decided -- TODO.

=cut

sub visible {
	my $this=shift;

	# TODO: test it.

	# Call parent class to deal with everything else.
	return $this->SUPER::visible;
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
