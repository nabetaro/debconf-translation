#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Gnome::Note - a note to show to the user

=cut

package Debconf::Element::Gnome::Note;
use strict;
use Debconf::Gettext;
use Gtk2;
use utf8;
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
	$this->widget(Gtk2::HBox->new(0, 0));

	my $text = Gtk2::TextView->new();
	my $textbuffer = $text->get_buffer;
	$text->show;
	$text->set_wrap_mode ("word");
	$text->set_editable (0);

	my $vscrollbar = Gtk2::VScrollBar->new; #$text->vadj);
	$vscrollbar->show;

	$this->widget->show;
	$this->widget->pack_start($text, 1, 1, 0);
	$this->widget->pack_start($vscrollbar, 0, 0, 0);

	$textbuffer->set_text($this->question->extended_description);

	$this->addbutton(gettext("Save (mail) Note"), sub {
	    my $dialog;
	    if ($this->Debconf::Element::Noninteractive::Note::sendmail(gettext("Debconf was asked to save this note, so it mailed it to you."))) {
		$dialog = Gtk2::MessageDialog->new(undef, "modal", "info",
						   "close", 
						   gettext("The note has been mailed."));
	    }
	    else {
		$dialog = Gtk2::MessageDialog->new(undef, "modal", "error",
						   "close", 
						   gettext("Unable to save note."));
	    }
	    $dialog->run;
	    $dialog->destroy;
	});

	$this->widget->show;
	$this->adddescription;
	$this->addwidget($this->widget);
	# No help button is added since the widget is the description.
}

=head1 AUTHOR

Eric Gillespie <epg@debian.org>
Gustavo Noronha Silva <kov@debian.org>

=cut

1
