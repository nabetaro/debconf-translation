#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Gtk::Note - Gtk text field

=cut

=head1 DESCRIPTION

This is a Gtk text field in the debconf dialog box.

=cut

package Debian::DebConf::Element::Gtk::Note;
use Gtk;
use strict;
use Debian::DebConf::Element; # perlbug
use base qw(Debian::DebConf::Element);

sub show {
	my $this = shift;
	my $vbox = new Gtk::VBox(0,5);
	my $text = $this->frontend->maketext(
			$this->question->extended_description);
	my $label = new Gtk::Label("This note has been saved in your mailbox");
	$vbox->pack_start($text, 1,1,0);
	$vbox->pack_start($label, 0,1,0);
	$text->show(); $label->show();
	$this->frontend->newques($this->question->description, $vbox);
	return '';
}

1
