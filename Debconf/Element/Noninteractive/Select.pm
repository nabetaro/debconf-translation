#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Noninteractive::Select - dummy select Element

=cut

package Debconf::Element::Noninteractive::Select;
use strict;
use base qw(Debconf::Element::Noninteractive);

=head1 DESCRIPTION

This is dummy select element.

=head1 METHODS

=over 4

=item show

The show method does not display anything. However, if the value of the
Question associated with it is not set, or is not one of the available
choices, then it will be set to the first item in the select list. This is
for consistency with the behavior of other select Elements.

=cut

sub show {
	my $this=shift;

	# Make sure the choices list is in the C locale, not localized.
	$this->question->template->i18n('');
	my @choices=$this->question->choices_split;
	$this->question->template->i18n(1);
	my $value=$this->question->value;
	$value='' unless defined $value;
	my $inlist=0;
	map { $inlist=1 if $_ eq $value } @choices;

	if (! $inlist) {
		if (@choices) {
			$this->value($choices[0]);
		}
		else {
			$this->value('');
		}
	}
	else {
		$this->value($value);
	}
}

=back

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
