#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Gnome::Boolean - check box widget

=cut

package Debconf::Element::Gnome::Boolean;
use strict;
use Gtk;
use base qw(Debconf::Element::Gnome);

=head1 DESCRIPTION

This is a check box widget.

=head1 METHODS

=over 4

=item init

Sets up the widget.

=cut

sub init {
	my $this=shift;

	$this->SUPER::init(@_);

	$this->widget(Gtk::CheckButton->new($this->question->description));
	$this->widget->show;
	$this->widget->set_active(($this->question->value eq 'true') ? 1 : 0);
	$this->addwidget($this->widget);
	$this->addhelp;
}

=item value

The value is true if the checkbox is checked, false otherwise.

=cut

sub value {
	my $this=shift;

	if ($this->widget->get_active) {
	    return "true";
	} else {
	    return "false";
	}
}

=back

=head1 AUTHOR

Eric Gillespie <epg@debian.org>

=cut

1
