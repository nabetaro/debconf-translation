#!/usr/bin/perl -w

package Debian::DebConf::Element::Gtk::Text;
use Gtk;
use strict;
use Debian::DebConf::Element::Base;
use Debian::DebConf::ConfigDb;
use vars qw(@ISA);
@ISA=qw(Debian::DebConf::Element::Base);

sub show {
	my $self = shift;
	$self->frontend->newques(
		$self->question->description, 
		$self->frontend->maketext(
			$self->question->extended_description));
}

1
