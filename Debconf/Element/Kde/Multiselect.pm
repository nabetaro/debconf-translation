#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Kde::Multiselect - group of check boxes

=cut

package Debconf::Element::Kde::Multiselect;
use strict;
use Qt;
use base qw(Debconf::Element::Kde Debconf::Element::Multiselect);

=head1 DESCRIPTION

Multiselect is implemented using a group of check boxes, one per option.

=head1 METHODS

=over 4

=item create

Creates and sets up the widgets.

=cut

sub create {
	my $this=shift;
	
	my @choices = $this->question->choices_split;
	my %default = map { $_ => 1 } $this->translate_default;
	
	$this->SUPER::create(@_);
	$this->startsect;
	$this->addhelp;
	$this->adddescription;
    
	my @buttons;
	my $vbox = Qt::VBoxLayout($this -> widget);
	for (my $i=0; $i <= $#choices; $i++) {
		$buttons[$i] = Qt::CheckBox($this->cur->top);
		$buttons[$i]->setText($choices[$i]);
		$buttons[$i]->show;
		$buttons[$i]->setChecked($default{$choices[$i]} ? 1 : 0);
		$buttons[$i]->setSizePolicy(Qt::SizePolicy(1, 1, 0, 0,
		$buttons[$i]->sizePolicy()->hasHeightForWidth()));
		$this->addwidget($buttons[$i]);
	}
	
	$vbox->addItem($this -> vspacer);
	$this->buttons(\@buttons);
	$this->endsect;
}

=item value

The value is based on which boxes are checked..

=cut

sub value {
	my $this = shift;
	my @choices = $this->question->choices_split;
	my @buttons = @{$this->buttons};
	my ($ret, $val);
	my @vals;
	for (my $i = 0; $i <= $#choices; $i++) {
	if ($buttons [$i] -> isChecked()) {
		push @vals, $this->translate_to_C($choices[$i]);
	}
	}
	return join(', ', $this->order_values(@vals));
}

=back

=head1 AUTHOR

Peter Rockai <mornfall@logisys.dyndns.org>

=cut

1
