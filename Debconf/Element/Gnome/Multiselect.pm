#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Gnome::Multiselect - a check list in a dialog box

=cut

package Debconf::Element::Gnome::Multiselect;
use strict;
use Gtk;
use Gnome;
use base qw(Debconf::Element);

sub init {
	my $this=shift;
	my @choices = $this->question->choices_split;

	$this->widget(Gtk::VBox->new(0, 0));
	$this->widget->show;

	# TODO: isn't there a gtk multiselct list box that could be used
	# instead of all these checkboxes?
	my @buttons;
	for (my $i=0; $i <= $#choices; $i++) {
	    $buttons[$i] = Gtk::CheckButton->new($choices[$i]);
	    $buttons[$i]->show;
	    $this->widget->pack_start($buttons[$i], 0, 0, 0);
	}

	$this->buttons(\@buttons);
}

=item value

The value is just the value field of the widget, translated back to the C
locale.

=cut

sub value {
	my $this=shift;
	my @choices=$this->question->choices_split;
	my @buttons = @{$this->buttons};
	my ($ret, $val);

	my @vals;
	for (my $i=0; $i <= $#choices; $i++) {
		if ($buttons[$i]->get_active()) {
			push @vals, $this->translate_to_C($choices[$i]);
		}
	}

	return join(', ', @vals);
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
