#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Gtk::String - Gtk text input field

=cut

=head1 DESCRIPTION

This is an input field element on the debconf dialog box.

=cut

package Debian::DebConf::Element::Gtk::String;
use Gtk;
use strict;
use Debian::DebConf::Element; # perlbug
use base qw(Debian::DebConf::Element);

sub show {
	my $this = shift;
	my $vbox = new Gtk::VBox(0,5);
	my $text = $this->frontend->maketext(
			$this->question->extended_description);
	my $entry = new Gtk::Entry;
	$entry->set_text($this->question->value)
		if defined $this->question->value;
	$vbox->pack_start($text, 1,1,0);
	$vbox->pack_start($entry, 0,1,0);
	$text->show(); $entry->show();
	my $result = $this->frontend->newques(
		$this->question->description, $vbox);
	return $entry->get_text;
}

1
