#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Slang::String - text input widget

=cut

package Debconf::Element::Slang::String;
use strict;
use Term::Stool::Input;
use base qw(Debconf::Element::Slang);

=head1 DESCRIPTION

This is a text input widget.

=cut

=head1 METHODS

=over 4

=cut

sub init {
	my $this=shift;

	my $default='';
	$default=$this->question->value if defined $this->question->value;
	$this->widgets([Term::Stool::Input->new(
		text => $default,
		preferred_width => 20,
	)]);
}

=item resize

Try to make the widget as wide as its preferred_width attrribute at a
minimum. If there's room for a widget that wide to fit on the same line as the
description, do so. Otherwise, put the widget on the next line.

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
		$widget->width($maxwidth - 1 - $description->width);
		$widget->xoffset($description->width + 2);
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

The value is just the text field of the associated widget.

=cut

sub value {
	my $this=shift;

	return $this->widgets->[0]->text;
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
