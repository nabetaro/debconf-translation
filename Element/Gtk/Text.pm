#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Gtk::Note - Gtk text field

=cut

=head1 DESCRIPTION

This is a Gtk text field in the debconf dialog box.

=cut

package Debian::DebConf::Element::Gtk::Text;
use Gtk;
use strict;
use Debian::DebConf::Element;
use Debian::DebConf::ConfigDb;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element);

sub show {
	my $self = shift;
	$self->frontend->newques(
		$self->question->description, 
		$self->frontend->maketext(
			$self->question->extended_description));
}

1
