#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Kde::Multiselect - group of check boxes

=cut

package Debconf::Element::Kde::Multiselect;
use strict;
use QtCore4;
use QtGui4;
use base qw(Debconf::Element::Kde Debconf::Element::Multiselect);
use Debconf::Encoding qw(to_Unicode);

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
	$this->adddescription;
	$this->addhelp;
    
	my @buttons;
	for (my $i=0; $i <= $#choices; $i++) {
		$buttons[$i] = Qt::CheckBox($this->cur->top);
		$buttons[$i]->setText(to_Unicode($choices[$i]));
		$buttons[$i]->show;
		$buttons[$i]->setChecked($default{$choices[$i]} ? 1 : 0);
		$this->addwidget($buttons[$i]);
	}
	
	$this->buttons(\@buttons);
	$this->endsect;
}

=item value

The value is based on which boxes are checked..

=cut

sub value {
	my $this = shift;
	my @buttons = @{$this->buttons};
	my ($ret, $val);
	my @vals;
	# we need untranslated templates for this
	$this->question->template->i18n('');
	my @choices=$this->question->choices_split;
	$this->question->template->i18n(1);
	
	for (my $i = 0; $i <= $#choices; $i++) {
	if ($buttons [$i] -> isChecked()) {
		push @vals, $choices[$i];
	}
	}
	return join(', ', $this->order_values(@vals));
}

# Multiple inheritance means we get Debconf::Element::visible by default.
*visible = \&Debconf::Element::Multiselect::visible;

=back

=head1 AUTHOR

Peter Rockai <mornfall@logisys.dyndns.org>

=cut

1
