#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Noninteractive - Dummy Element

=cut

package Debconf::Element::Noninteractive;
use strict;
use base qw(Debconf::Element);

=head1 DESCRIPTION

This is noninteractive dummy element. When told to display itself, it does
nothing.

=head1 METHODS

=over 4

=item visible

This type of element is not visible.

=cut

sub visible {
	my $this=shift;
	
	return;
}

=item show

Set the value to the default, or blank if no default is available.

=cut

sub show {
	my $this=shift;

	my $default='';
	$default=$this->question->value if defined $this->question->value;
	$this->value($default);
}

=back

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
