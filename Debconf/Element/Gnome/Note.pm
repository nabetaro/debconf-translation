#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Gnome::Note - a note to show to the user

=cut

package Debconf::Element::Gnome::Note;
use strict;
use Debconf::Gettext;
use Gtk;
use Gnome;
use base qw(Debconf::Element::Gnome Debconf::Element::Noninteractive::Note);

=head1 DESCRIPTION

This is a note to show to the user. Notes have an associated button widget
that can be pressed to save the note.

=cut

sub init {
	my $this=shift;

	$this->SUPER::init(@_);

	$this->widget(Gtk::VBox->new(0, 0));

	my $text = Gtk::Text->new(0, 0);
	$text->show;
	$text->set_word_wrap(1);

	my $vscrollbar = Gtk::VScrollbar->new($text->vadj);
	$vscrollbar->show;

	my $hbox = Gtk::HBox->new(0, 0);
	$hbox->show;
	$hbox->pack_start($text, 1, 1, 0);
	$hbox->pack_start($vscrollbar, 0, 0, 0);
	$this->widget->pack_start($hbox, 1, 1, 0);

	$text->insert(undef, undef, undef,
		      $this->question->extended_description);

	my $button = Gtk::Widget->new("Gtk::Button",
		-label => gettext("Save Note"),
		-signal::clicked => sub {
			my $msg;
			if ($this->sendmail(gettext("Debconf was asked to save this note, so it mailed it to you."))) {
				$msg = Gnome::MessageBox->new(gettext("The note has been mailed."), "info", "Button_Ok");
			}
			else {
				$msg = Gnome::MessageBox->new(gettext("Unable to save note."), "error", "Button_Ok");
			}
			$msg->show;
			$msg->run;
		}
	);
	$button->show;

	$hbox = Gtk::HBox->new(0, 0);
	$hbox->show;
	$hbox->pack_start($button, 1, 0, 0);
	$this->widget->pack_start($hbox, 0, 0, 0);

	$this->widget->show;
	$this->adddescription;
	$this->addwidget($this->widget);
	# No button is added since the widget is the description.
}

=head1 AUTHOR

Eric Gillespie <epg@debian.org>

=cut

1
