#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Slang::Select - drop down select box widget

=cut

package Debconf::Element::Slang::Select;
use strict;
use Term::Stool::DropDown;
use base qw(Debconf::Element::Select Debconf::Element::Slang);

=head1 DESCRIPTION

This is a drop down select box widget.

=cut

=head1 METHODS

=over 4

=cut

sub init {
	my $this=shift;

	my $default=$this->translate_default;
	my @choices=$this->question->choices_split;

	# Find cursor position.
	my $cursor=1;
	for (my $x=0; $x <= $#choices ; $x++) {
		if ($choices[$x] eq $default) {
			$cursor=$x;
			last;
		}
	}

	$this->widget(Term::Stool::DropDown->new(
		list => Term::Stool::List->new(
			contents => [@choices],
			cursor => $cursor,
		),
	));
	# The widget prefers to be just wide enough for the list box.
	$this->widget->preferred_width($this->widget->list->width + 5);
}

=item value

The value is just the value field of the widget, translated back to the C
locale.

=cut

sub value {
	my $this=shift;

	return $this->translate_to_C($this->widget->list->value);
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
