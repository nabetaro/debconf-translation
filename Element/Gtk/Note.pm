#!/usr/bin/perl -w

package Debian::DebConf::Element::Gtk::Note;
use Gtk;
use strict;
use Debian::DebConf::Element::Base;
use Debian::DebConf::ConfigDb;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element::Base);

sub show {
	my $self = shift;
	my $vbox = new Gtk::VBox(0,5);
	my $text = $self->frontend->maketext(
			$self->question->extended_description);
	my $label = new Gtk::Label("This note has been saved in your mailbox");
	$vbox->pack_start($text, 1,1,0);
	$vbox->pack_start($label, 0,1,0);
	$text->show(); $label->show();
	$self->frontend->newques($self->question->description, $vbox);
}

1
