#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Gnome::Select - drop down select box widget

=cut

package Debian::DebConf::Element::Gnome::Select;
use strict;
use Gtk;
use Gnome;
use Debian::DebConf::Element::Gnome; # perlbug
use base qw(Debian::DebConf::Element::Select Debian::DebConf::Element::Gnome);

=head1 DESCRIPTION

This is a drop down select box widget.

=cut

=head1 METHODS

=over 4

=cut

sub get_history {
    my $this=shift;
    my $menu = $this->get_menu;
    my @children = $menu->children;
    my $item = $menu->get_active;
    my $i;

    for ($i=0; $i <= $#children; $i++) {
	if ($children[$i] eq $item) {
	    last;
	}
    }

    return $i;
}

sub init {
	my $this=shift;

	my $menu = new Gtk::Menu;
	$menu->show;
	my $previous = undef;
	my $menu_item;
	my $history = 0;

	my $default=$this->translate_default;
	my @choices=$this->{question}->choices_split;

	$this->{widget} = new Gtk::Combo;
	$this->{widget}->show;

	$this->{widget}->set_popdown_strings(@choices);
	$this->{widget}->set_value_in_list(1, 0);
	$this->{widget}->entry->set_editable(0);

	if (defined($default) and length($default) != 0) {
	    $this->{widget}->entry->set_text($default);
	} else {
	    $this->{widget}->entry->set_text($choices[0]);
	}
}

=item value

The value is just the value field of the widget, translated back to the C
locale.

=cut

sub value {
	my $this=shift;
	my @choices=$this->{question}->choices_split;

	return $this->translate_to_C($this->{widget}->entry->get_chars(0, -1));
}

=back

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
