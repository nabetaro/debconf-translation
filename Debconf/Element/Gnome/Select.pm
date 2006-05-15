#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Gnome::Select - drop down select box widget

=cut

package Debconf::Element::Gnome::Select;
use strict;
use Gtk2;
use Gnome2;
use utf8;
use Debconf::Encoding qw(to_Unicode);
use base qw(Debconf::Element::Gnome Debconf::Element::Select);

=head1 DESCRIPTION

This is a drop down select box widget.

=cut

sub init {
	my $this=shift;

	my $default=$this->translate_default;
	my @choices= map { to_Unicode($_) } $this->question->choices_split;

	$this->SUPER::init(@_);

	$this->widget(Gtk2::Combo->new);
	$this->widget->show;

	$this->widget->set_popdown_strings(@choices);
	$this->widget->set_value_in_list(1, 0);
	$this->widget->entry->set_editable(0);

	if (defined($default) and length($default) != 0) {
		$this->widget->entry->set_text(to_Unicode($default));
	}
	else {
		$this->widget->entry->set_text($choices[0]);
	}

	$this->adddescription;
	$this->addwidget($this->widget);
	$this->tip( $this->widget->entry );
	$this->addhelp;
}

=item value

The value is just the value field of the widget, translated back to the C
locale.

=cut

sub value {
	my $this=shift;

	return $this->translate_to_C_uni($this->widget->entry->get_chars(0, -1));
}

# Multiple inheritance means we get Debconf::Element::visible by default.
*visible = \&Debconf::Element::Select::visible;

=back

=head1 AUTHOR

Eric Gillespie <epg@debian.org>
Gustavo Noronha Silva <kov@debian.org>

=cut

1
