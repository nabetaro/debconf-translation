#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Gnome::Password - password input widget

=cut

package Debconf::Element::Gnome::Password;
use strict;
use Gtk;
use Gnome;
use base qw(Debconf::Element::Gnome);

=head1 DESCRIPTION

This is a password input widget.

=cut

=head1 METHODS

=over 4

=cut

sub init {
	my $this=shift;

	$this->SUPER::init(@_);
	$this->adddescription;

	$this->widget(Gtk::Entry->new);
	$this->widget->show;
	$this->widget->set_visibility(0);
	$this->addwidget($this->widget);
	$this->addbutton;
}

=item value

If the widget's value field is empty, return the default.

=cut

sub value {
	my $this=shift;
	
	my $text = $this->widget->get_chars(0, -1);
	$text = $this->question->value if $text eq '';
	return $text;
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1