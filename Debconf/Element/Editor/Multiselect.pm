#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Editor::MultiSelect - select from a list of choices

=cut

package Debconf::Element::Editor::Multiselect;
use strict;
use Debconf::Gettext;
use base qw(Debconf::Element::Multiselect);

=head1 DESCRIPTION

Presents a list of choices to be selected amoung. Multiple selection is
allowed.

=head1 METHODS

=over 4

=cut

sub show {
	my $this=shift;

	my @choices=$this->question->choices_split;

	$this->frontend->comment($this->question->extended_description."\n\n".
		"(".gettext("Choices").": ".join(", ", @choices).")\n".
		gettext("(Enter zero or more items separated by a comma followed by a space (', ').)")."\n".
		$this->question->description."\n");

	$this->frontend->item($this->question->name, join ", ", $this->translate_default);
}

=item value

When value is set, convert from a space-separated list into the internal
format. At the same time, validate each item and make sure it is allowable,
or remove it.

=cut

sub value {
	my $this=shift;

	return $this->SUPER::value() unless @_;
	my @values=split(',\s+', shift);

	my %valid=map { $_ => 1 } $this->question->choices_split;
	
	$this->SUPER::value(join(', ', $this->order_values(
			map { $this->translate_to_C($_) }
			grep { $valid{$_} } @values)));
}

=back

=head1 AUTHOR

Joey Hess <joeyh@debian.org>

=cut

1
