#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Slang - element containing a slang widget

=cut

package Debconf::Element::Slang;
use strict;
use base qw(Debconf::Element);

=head1 DESCRIPTION

This is a type of Element used by the slang FrontEnd. It contains a Widget
from Term::Stool.

=head1 FIELDS

=over 4

=item widget

This is the primary input widget associated with this Element. It should
automatically be made when this Element is instantiated.

=item widget_description

This is a secondary widget, that is used to display the short description.

=item sameline

This should be set whenever the widget occupys the same line as its short
description.

=item preferred_width

This is how wide the widget prefers to be. If possible, the widget will be
made that wide, but it might have to be narrower.

=back

=head1 METHODS

=over 4

=item resize

This is called when the widget is resized.

By default, this method will try to make the widget as wide as its
preferred_width, and on the same line as the widget_description. If there's
not room, the widget goes on the next line.

=cut

sub resize {
	my $this=shift;
	my $widget=$this->widget;
	my $description=$this->widget_description;
	my $maxwidth=$widget->container->width - 4;

	if ($maxwidth > $widget->preferred_width + $description->width) {
		$widget->sameline(1);
		$widget->width($widget->preferred_width);
		$widget->xoffset($description->width + 2);
	}
	elsif ($maxwidth > $widget->preferred_width) {
		$widget->sameline(0);
		$widget->width($widget->preferred_width);
		$widget->xoffset(1);
	}
	else {
		$widget->sameline(0);
		$widget->width($maxwidth);
		$widget->xoffset(1);
	}
}

=item value

Return the value the user entered.

Defaults to returning nothing.

=cut

sub value {
	my $this=shift;

	return '';
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
