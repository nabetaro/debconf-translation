#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Gnome::Text - a bit of text to show to the user.

=cut

package Debian::DebConf::Element::Gnome::Text;
use strict;
use Debian::DebConf::Gettext;
use Gtk;
use Gnome;
use Debian::DebConf::Element::Gnome; # perlbug
use base qw(Debian::DebConf::Element::Gnome);

=head1 DESCRIPTION

This is a bit of text to show to the user.

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

	$this->{widget}->show;
}

1
