#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Slang::Boolean - check box widget

=cut

package Debconf::Element::Slang::Boolean;
use strict;
use Term::Stool::CheckBox;
use Debconf::Element::Slang; # perlbug
use base qw(Debconf::Element::Slang);

=head1 DESCRIPTION

This is a check box widget.

=cut

=head1 METHODS

=over 4

=cut

sub init {
	my $this=shift;

	$this->widget(Term::Stool::CheckBox->new(
		checked => (defined $this->question->value && $this->question->value eq 'true') ? 1 : 0,
	));
}

=item resize

The check box always must go on the same line as the description, on its left
hand side.

=cut

sub resize {
	my $this=shift;
	my $widget=$this->widget;
	my $description=$this->widget_description;
	my $maxwidth=$widget->container->width - 4;

	$widget->sameline(1);
	$widget->xoffset(1);
	$description->xoffset(1 + $widget->width + 1);
	$description->width($widget->container->width - 4 -
		$description->xoffset + 1);
}

=item value

The value is true if the checkbox is checked, false otherwise.

=cut

sub value {
	my $this=shift;

	my $ret='false';
	$ret='true' if $this->widget->checked;
	return $ret;
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
