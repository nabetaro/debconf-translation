#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Noninteractive::Select - dummy select Element

=cut

=head1 DESCRIPTION

This is dummy select element.

=cut

=head1 METHODS

=cut

package Debian::DebConf::Element::Noninteractive::Select;
use strict;
use Debian::DebConf::Element::Noninteractive; # perlbug
use base qw(Debian::DebConf::Element::Noninteractive);

=head2 show

The show method does not display anything. However, if the value of the
Question associated with it is not set, or is not one of the available
choices, then it will be set to the first item in the select list. This is
for consitancy with other select Elements.

=cut

sub show {
	my $this=shift;

	my @choices=$this->question->choices_split;
	my $value=$this->question->value;
	$value='' unless defined $value;
	my $inlist=0;
	map { $inlist=1 if $_ eq $value } @choices;

	if (! $inlist) {
		my @choices=$this->question->choices_split;
		if (@choices) {
			$this->question->value($choices[0]);
		}
		else {
			$this->question->value('');
		}
	}
	
	return $this->question->value;
}

1
