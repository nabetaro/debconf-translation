#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Gnome::Text - a bit of text to show to the user.

=cut

package Debconf::Element::Gnome::Text;
use strict;
use Debian::DebConf::Gettext;
use Gtk;
use Gnome;
use base qw(Debian::DebConf::Element);

=head1 DESCRIPTION

This is a bit of text to show to the user.

=cut

sub init {
	my $this=shift;

	$this->widget(Gtk::VBox(0, 0));

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

	$this->widget->show;
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
