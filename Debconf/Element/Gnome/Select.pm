#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Gnome::Select - drop down select box widget

=cut

package Debconf::Element::Gnome::Select;
use strict;
use Gtk2;
use utf8;
use Debconf::Encoding qw(to_Unicode);
use base qw(Debconf::Element::Gnome Debconf::Element::Select);

=head1 DESCRIPTION

This is a drop down select box widget.

=cut

sub init {
	my $this=shift;

	my $default=$this->translate_default;
	my @choices=$this->question->choices_split;

	$this->SUPER::init(@_);

	$this->widget(Gtk2::ComboBox->new_text);
	$this->widget->show;

	foreach my $choice (@choices) {
		$this->widget->append_text(to_Unicode($choice));
	}

	$this->widget->set_active(0);
	for (my $choice=0; $choice <= $#choices; $choice++) {
		if ($choices[$choice] eq $default) {
			$this->widget->set_active($choice);
			last;
		}
	}

	$this->adddescription;
	$this->addwidget($this->widget);
	$this->tip( $this->widget );
	$this->addhelp;
}

=item value

The value is just the value field of the widget, translated back to the C
locale.

=cut

sub value {
	my $this=shift;

	return $this->translate_to_C_uni($this->widget->get_active_text);
}

# Multiple inheritance means we get Debconf::Element::visible by default.
*visible = \&Debconf::Element::Select::visible;

=back

=head1 AUTHOR

Eric Gillespie <epg@debian.org>
Gustavo Noronha Silva <kov@debian.org>

=cut

1
