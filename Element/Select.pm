#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Select - Base select input element

=cut

package Debian::DebConf::Element::Select;
use strict;
use Debian::DebConf::Element; # perlbug
use base qw(Debian::DebConf::Element);

=head1 DESCRIPTION

This is a base Select input element.

=head1 METHODS

=over 4

=item show

Select elements are not really visible if there are less than two choices
for them.

=cut

sub visible {
	my $this=shift;
	
	my @choices=$this->question->choices_split;
	return ($#choices > 0);
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
