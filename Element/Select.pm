#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Select - Base select input element

=cut

=head1 DESCRIPTION

This is a base Select input element.

=cut

=head1 METHODS

=cut

package Debian::DebConf::Element::Select;
use Debian::DebConf::Element;
use strict;
use vars qw($AUTOLOAD);
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element);

=head2 visible

Select elements are not visible unless they have 2 or more choices to select from.

=cut

sub visible {
	my $this=shift;

	my @choices=$this->question->choices_split;

	return '' if $#choices < 1;
	
	# Call parent class to deal with everything else.
	return $this->SUPER::visible;
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
