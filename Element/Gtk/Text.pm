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
use Debian::DebConf::Element; # perlbug
use base qw(Debian::DebConf::Element);

sub show {
	my $this = shift;
	$this->frontend->newques(
		$this->question->description, 
		$this->frontend->maketext(
			$this->question->extended_description));
	return '';
}

1
