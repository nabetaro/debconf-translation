#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Gnome::String - text input widget

=cut

package Debconf::Element::Gnome::String;
use strict;
use Gtk;
use Gnome;
use base qw(Debconf::Element::Gnome);

=head1 DESCRIPTION

This is a text input widget.

=cut

sub init {
	my $this=shift;

	$this->SUPER::init(@_);

	$this->widget(Gtk::Entry->new);
	$this->widget->show;

	my $default='';
	$default=$this->question->value if defined $this->question->value;

	$this->widget->set_text($default);

	$this->adddescription;
	$this->addwidget($this->widget);
	$this->addbutton;
}

=item value

The value is just the text field of the associated widget.

=cut

sub value {
	my $this=shift;

	return $this->widget->get_chars(0, -1);
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
