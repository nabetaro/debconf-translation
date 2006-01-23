#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Gnome::Error - an error message to show to the user

=cut

package Debconf::Element::Gnome::Error;
use strict;
use Debconf::Gettext;
use Gtk2;
use utf8;
use Debconf::Encoding qw(to_Unicode);
use base qw(Debconf::Element::Gnome);

=head1 DESCRIPTION

This is an error message to show to the user.

=cut

sub init {
	my $this=shift;
	my $extended_description = to_Unicode($this->question->extended_description);

	$this->SUPER::init(@_);
	$this->multiline(1);
	$this->fill(1);
	$this->expand(1);
	$this->widget(Gtk2::HBox->new(0, 0));

	my $image = Gtk2::Image->new_from_stock("gtk-dialog-error", "dialog");
	$image->show;

	my $text = Gtk2::TextView->new();
	my $textbuffer = $text->get_buffer;
	$text->show;
	$text->set_wrap_mode ("word");
	$text->set_editable (0);

	my $scrolled_window = Gtk2::ScrolledWindow->new();
	$scrolled_window->show;
	$scrolled_window->set_policy('automatic', 'automatic');
	$scrolled_window->set_shadow_type('in');
	$scrolled_window->add ($text);

	$this->widget->show;
	$this->widget->pack_start($image, 0, 0, 6);
	$this->widget->pack_start($scrolled_window, 1, 1, 0);

	$textbuffer->set_text($extended_description);

	$this->widget->show;
	$this->adddescription;
	$this->addwidget($this->widget);
	# No help button is added since the widget is the description.
}

=head1 AUTHOR

Eric Gillespie <epg@debian.org>
Gustavo Noronha Silva <kov@debian.org>
Colin Watson <cjwatson@debian.org>

=cut

1
