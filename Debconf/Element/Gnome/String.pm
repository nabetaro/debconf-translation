#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Gnome::String - text input widget

=cut

package Debian::DebConf::Element::Gnome::String;
use strict;
use Gtk;
use Gnome;
use Debian::DebConf::Element::Gnome; # perlbug
use base qw(Debian::DebConf::Element::Gnome);

=head1 DESCRIPTION

This is a text input widget.

=cut

=head1 METHODS

=over 4

=cut

sub init {
	my $this=shift;

	my $default='';
	$default=$this->{question}->value if defined $this->{question}->value;

	$this->{widget} = new Gtk::Entry;
	$this->{widget}->show;

#	Which of these is correct?
#	$this->{widget}->set_text($default);
	$this->{widget}->set_text($this->{question}->value);
}

=item value

The value is just the text field of the associated widget.

=cut

sub value {
	my $this=shift;

	return $this->{widget}->get_chars(0, -1);
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
