#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Gnome::Password - password input widget

=cut

package Debian::DebConf::Element::Gnome::Password;
use strict;
use Gtk;
use Gnome;
use Debian::DebConf::Element::Gnome; # perlbug
use base qw(Debian::DebConf::Element::Gnome);

=head1 DESCRIPTION

This is a password input widget.

=cut

=head1 METHODS

=over 4

=cut

sub init {
	my $this=shift;

	$this->{widget} = new Gtk::Entry;
	$this->{widget}->show;
	$this->{widget}->set_visibility(0);
}

=item value

If the widget''s value field is empty, return the default.

=cut

sub value {
	my $this=shift;
	
	my $text = $this->{widget}->get_chars(0, -1);
	$text = $this->{question}->value if $text eq '';
	return $text;
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
