#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Gnome::Multiselect - a check list in a dialog box

=cut

package Debconf::Element::Gnome::Multiselect;
use strict;
use Gtk2;
use utf8;
use Debconf::Encoding qw(to_Unicode);
use base qw(Debconf::Element::Gnome Debconf::Element::Multiselect);

sub init {
	my $this=shift;
	my @choices = map { to_Unicode($_) } $this->question->choices_split;
        my %default=map { to_Unicode($_) => 1 } $this->translate_default;

	$this->SUPER::init(@_);
	$this->multiline(1);

	$this->adddescription;

        $this->widget(Gtk2::ScrolledWindow->new);
        $this->widget->show;
        $this->widget->set_policy('automatic', 'automatic');
	
	# TODO: isn't there a gtk multiselct list box that could be used
	# instead of all these checkboxes?
	my @buttons;
	my $vbox = Gtk2::VBox->new(0, 0);
        for (my $i=0; $i <= $#choices; $i++) {
		$buttons[$i] = Gtk2::CheckButton->new($choices[$i]);
		$buttons[$i]->show;
		$buttons[$i]->set_active($default{$choices[$i]} ? 1 : 0);
		$vbox->pack_start($buttons[$i], 0, 0, 0);
	}
        $vbox->show;
        $this->widget->add_with_viewport($vbox);
    
	$this->buttons(\@buttons);
	
	$this->addwidget($this->widget);
	$this->addhelp;

	# we want to be both expanded and filled
	$this->fill(1);
	$this->expand(1);

}

=item value

The value is just the value field of the widget, translated back to the C
locale.

=cut

sub value {
	my $this=shift;
	my @buttons = @{$this->buttons};
	my ($ret, $val);
	
	my @vals;
	# we need untranslated templates for this
	$this->question->template->i18n('');
	my @choices=$this->question->choices_split;
	$this->question->template->i18n(1);
	
	for (my $i=0; $i <= $#choices; $i++) {
		if ($buttons[$i]->get_active()) {
			push @vals, $choices[$i];
		}
	}

	return join(', ', $this->order_values(@vals));
}

=head1 AUTHOR

Eric Gillespie <epg@debian.org>
Gustavo Noronha Silva <kov@debian.org>

=cut

1
