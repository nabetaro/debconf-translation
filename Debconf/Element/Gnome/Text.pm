#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Gnome::Text - a bit of text to show to the user.

=cut

package Debconf::Element::Gnome::Text;
use strict;
use Debconf::Gettext;
use Gtk2;
use utf8;
use base qw(Debconf::Element::Gnome);

=head1 DESCRIPTION

This is a bit of text to show to the user.

=cut

sub init {
	my $this=shift;

	$this->SUPER::init(@_);
	$this->adddescription; # yeah, that's all
}

=head1 AUTHOR

Eric Gillespie <epg@debian.org>
Gustavo Noronha Silva <kov@debian.org>

=cut

1
