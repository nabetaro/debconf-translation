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
use Debian::DebConf::Element;
use Debian::DebConf::ConfigDb;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element);

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
