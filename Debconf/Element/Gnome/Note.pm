#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Gnome::Note - a note to show to the user

=cut

package Debconf::Element::Gnome::Note;
use strict;
use Debconf::Gettext;
use Gtk;
use Gnome;
use Debconf::Element::Noninteractive::Note;
use base qw(Debconf::Element::Gnome);

=head1 DESCRIPTION

This is a note to show to the user. Notes have an associated button widget
that can be pressed to save the note.

=cut

sub init {
	my $this=shift;

	$this->SUPER::init(@_);
	$this->multiline(1);
	$this->widget(Gtk::HBox->new(0, 0));

	my $text = Gtk::Text->new(0, 0);
	$text->show;
	$text->set_word_wrap(1);

	my $vscrollbar = Gtk::VScrollbar->new($text->vadj);
	$vscrollbar->show;

	$this->widget->show;
	$this->widget->pack_start($text, 1, 1, 0);
	$this->widget->pack_start($vscrollbar, 0, 0, 0);

	$text->insert(undef, undef, undef,
		      $this->question->extended_description);

	$this->addbutton(gettext("Save (mail) Note"), sub {
	    my $msg;
	    if ($this->Debconf::Element::Noninteractive::Note::sendmail(gettext(
                   "Debconf was asked to save this " .
		   "note, so it mailed it to you."))) {
		$msg = Gnome::MessageBox->new(gettext(
                    "The note has been mailed."), "info", "Button_Ok");
	    }
	    else {
		$msg = Gnome::MessageBox->new(gettext(
                    "Unable to save note."), "error", "Button_Ok");
	    }
	    $msg->show;
	    $msg->run;
	});

	$this->widget->show;
	$this->adddescription;
	$this->addwidget($this->widget);
	# No help button is added since the widget is the description.
}

=head1 AUTHOR

Eric Gillespie <epg@debian.org>

=cut

1
