#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Gtk::Password - Gtk password input field

=cut

=head1 DESCRIPTION

This is an password input element on the debconf dialog box.

=cut

package Debian::DebConf::Element::Gtk::Password;
use Gtk;
use strict;
use Debian::DebConf::Element; # perlbug
use base qw(Debian::DebConf::Element);

sub show {
	my $self = shift;
	my $vbox = new Gtk::VBox(0,5);
	my $text = $self->frontend->maketext(
			$self->question->extended_description);
	my $entry = new Gtk::Entry;
	$entry->set_text($self->question->value)
		if defined $self->question->value;
	$entry->set_visibility(0);		
	$vbox->pack_start($text, 1,1,0);
	$vbox->pack_start($entry, 0,1,0);
	$text->show(); $entry->show();
	my $result = $self->frontend->newques(
		$self->question->description, $vbox);
	return $entry->get_text;
}

1
