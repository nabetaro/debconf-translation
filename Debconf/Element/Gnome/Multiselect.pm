#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Gnome::Multiselect - a check list in a dialog box

=cut

package Debian::DebConf::Element::Gnome::Multiselect;
use strict;
use Gtk;
use Gnome;
use Debian::DebConf::Element::Gnome; # perlbug
use base qw(Debian::DebConf::Element::Gnome);

sub init {
	my $this=shift;
	my @choices = $this->{question}->choices_split;

	$this->{widget} = new Gtk::VBox(0, 0);
	$this->{widget}->show;

	my @buttons;
	for (my $i=0; $i <= $#choices; $i++) {
	    $buttons[$i] = new Gtk::CheckButton($choices[$i]);
	    $buttons[$i]->show;
	    $this->{widget}->pack_start($buttons[$i], 0, 0, 0);
	}

	$this->{buttons} = \@buttons;
}

=item value

The value is just the value field of the widget, translated back to the C
locale.

=cut

sub value {
	my $this=shift;
	my @choices=$this->{question}->choices_split;
	my @buttons = @{$this->{buttons}};
	my ($ret, $val);

	my @vals;
	my $j = 0;
	for (my $i=0; $i <= $#choices; $i++) {
	    if ($buttons[$i]->get_active()) {
		$vals[$j++] = $choices[$i];
	    }
	}

	$ret = $vals[0];
	for (my $i=1; $i <= $#vals; $i++) {
	    $ret = "$ret, $vals[$i]";
	}

	return $this->translate_to_C($ret);
}

1
