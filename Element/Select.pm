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
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element);

=head2 show

Select elements are not really shown if there are less than two choices.
However, it is useful to still set the value of their accociated Question
as if they were shown, for consitency.

This method will return one if the element really should be shown.

=cut

sub show {
	my $this=shift;
	
	my @choices=$this->question->choices_split;
	if ($#choices < 1) {
		$this->question->value($choices[0]) if $#choices == 0;
		$this->question->value('') if $#choices == -1;
		return '';
	}
	return 1;
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
