#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Slang::String - text input widget

=cut

package Debconf::Element::Slang::String;
use strict;
use Term::Stool::Input;
use Debconf::Element::Slang; # perlbug
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
	$this->widget(Term::Stool::Input->new(
		text => $default,
		preferred_width => 20,
	));
}

=item resize

Try to make the widget as wide as its preferred_width attrribute at a
minimum. If there's room for a widget that wide to fix on the same line as the
description, do so. Otherwise, put the widget on the next line.

=cut

sub resize {
	my $this=shift;
	my $widget=$this->widget;
	my $description=$this->widget_description;
	my $maxwidth=$widget->container->width - 4;

	if ($maxwidth > $widget->preferred_width + $description->width) {
		$widget->sameline(1);
		$widget->width($maxwidth - 1 - $description->width);
		$widget->xoffset($description->width + 2);
	}
	else {
		$widget->sameline(0);
		$widget->width($maxwidth);
		$widget->xoffset(1);
	}
}

=item value

The value is just the text field of the associated widget.

=cut

sub value {
	my $this=shift;

	return $this->widget->text;
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
