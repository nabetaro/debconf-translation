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

=item widgets

This is an array of primary input widgets associated with this Element. 
Typically, the array only contains one widget, but in exceptional cases
more may be needed.

=item widget_description

This is a secondary widget that is used to display the short description.
It will be created by the frontend.

=item preferred_width

This is how wide the widgets prefer to be. If possible, the widgets will be
made that wide, but they might have to be narrower.

=back

=head1 METHODS

=over 4

=item widgets

Returns the widget(s) that will be used to display this Element to the
user. If the widgets already exist, they are just returned. If they do not
yet exist, they are created, by calling the make_widgets method, and the
resulting widgets are stashed away.

=cut

sub widgets {
	my $this=shift;

	return $this->_widgets if $this->_widgets;
	return $this->_widgets([$this->make_widgets]);
}

=item make_widgets

Makes the widgets that will be used to display this Element to the
user. Just return the widget or widgets.

=cut

sub make_widgets {
	die "make_widgets not overridden by child class";
}

=item resize

This is a stock resize method that only supports one widget.
It is called when the widget is to be resized, and a number is passed in,
giving the starting y offset for widgets. It should return the ending
offset of the last widget.

By default, this method will try to make the widget as wide as its
preferred_width, and on the same line as the widget_description. If there's
not room, the widget goes on the next line.

=cut

sub resize {
	my $this=shift;
	my $y=shift;
	
	my $widget=$this->widgets->[0];
	my $description=$this->widget_description;
	my $maxwidth=$widget->container->width - 4;
	my $sameline;

	if ($maxwidth > $widget->preferred_width + $description->width) {
		$sameline=1;
		$widget->width($widget->preferred_width);
		$widget->xoffset($description->width + 2);
	}
	elsif ($maxwidth > $widget->preferred_width) {
		$sameline=0;
		$widget->width($widget->preferred_width);
		$widget->xoffset(1);
	}
	else {
		$sameline=0;
		$widget->width($maxwidth);
		$widget->xoffset(1);
	}
	$description->yoffset($y);
	$description->resize;
	$y++ unless $sameline;
	$widget->yoffset($y);

	return $y;
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
