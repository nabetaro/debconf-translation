#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Gnome::Password - password input widget

=cut

package Debconf::Element::Gnome::Password;
use strict;
use Gtk2;
use utf8;
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

	$this->widget(Gtk2::Entry->new);
	$this->widget->show;
	$this->widget->set_visibility(0);
	$this->addwidget($this->widget);
	$this->tip( $this->widget );
	$this->addhelp;
}

=item value

If the widget's value field is empty, return the default.

=cut

sub value {
	my $this=shift;
	
	# FIXME in which encoding?
	my $text = $this->widget->get_chars(0, -1);
	$text = $this->question->value if $text eq '';
	return $text;
}

=back

=head1 AUTHOR

Eric Gillespie <epg@debian.org>
Gustavo Noronha Silva <kov@debian.org>

=cut

1
