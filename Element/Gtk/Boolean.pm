#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Gtk::Boolean - Gtk check box

=cut

=head1 DESCRIPTION

This is a check box element in the debconf dialog box.

=cut

package Debian::DebConf::Element::Gtk::Boolean;
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
	my $check = new Gtk::CheckButton($self->question->description);
	$check->set_active($self->question->value eq "true" ? 1 : 0)
		if defined $self->question->value;

	$vbox->pack_start($text, 1,1,0);
	$vbox->pack_start($check, 0,1,0);
	$text->show(); $check->show();

	my $result = $self->frontend->newques(
			$self->question->description, $vbox);

	if ($result eq "change") {
		$self->question->value($check->active ? "true" : "false");
		$self->question->flag_isdefault("false");
	}
	return $result;
}

1
