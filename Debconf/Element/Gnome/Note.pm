#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Gnome::Note - a note to show to the user

=cut

package Debian::DebConf::Element::Gnome::Note;
use strict;
use Debian::DebConf::Gettext;
use Gtk;
use Gnome;
use Debian::DebConf::Element::Gnome; # perlbug
use base qw(Debian::DebConf::Element::Gnome
	    Debian::DebConf::Element::Noninteractive::Note);

=head1 DESCRIPTION

This is a note to show to the user. Notes have an associated button widget
that can be pressed to save the note.

=cut

sub init {
	my $this=shift;

	$this->{widget} = new Gtk::VBox(0, 0);

	my $text = new Gtk::Text(0, 0);
	$text->show;
	$text->set_word_wrap(1);

	my $vscrollbar = new Gtk::VScrollbar($text->vadj);
	$vscrollbar->show;

	my $hbox = new Gtk::HBox(0, 0);
	$hbox->show;
	$hbox->pack_start($text, 1, 1, 0);
	$hbox->pack_start($vscrollbar, 0, 0, 0);
	$this->{widget}->pack_start($hbox, 1, 1, 0);

	$text->insert(undef, undef, undef,
		      $this->{question}->extended_description);

	my $button = new Gtk::Widget("Gtk::Button",
				     -label => gettext("Save Note"),
				     -signal::clicked => sub {
					 if ($this->sendmail(gettext("Debconf was asked to save this note, so it mailed it to you."))) {
					     my $msg = new Gnome::MessageBox(gettext("The note has been mailed to root"), "info", "Button_Ok");
					     $msg->show;
					     $msg->run;
					 } else {
					     my $msg = new Gnome::MessageBox(gettext("Unable to save note."), "error", "Button_Ok");
					     $msg->show;
					     $msg->run;
					 }});
	$button->show;

	$hbox = new Gtk::HBox(0, 0);
	$hbox->show;
	$hbox->pack_start($button, 1, 0, 0);
	$this->{widget}->pack_start($hbox, 0, 0, 0);

	$this->{widget}->show;
}

1
