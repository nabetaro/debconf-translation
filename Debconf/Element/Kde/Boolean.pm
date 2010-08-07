#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Kde::Boolean - check box widget

=cut

package Debconf::Element::Kde::Boolean;
use strict;
use QtCore4;
use QtGui4;
use base qw(Debconf::Element::Kde);
use Debconf::Encoding qw(to_Unicode);

=head1 DESCRIPTION

This is a check box widget.

=head1 METHODS

=over 4

=item create

Creates and sets up the widget.

=cut

sub create {
	my $this=shift;
	
	$this->SUPER::create(@_);
	
	$this->startsect;
	$this->widget(Qt::CheckBox( to_Unicode($this->question->description)));
	$this->widget->setChecked(($this->question->value eq 'true') ? 1 : 0);
	$this->widget->setText(to_Unicode($this->question->description));
	$this->adddescription;
	$this->addhelp;
	$this->addwidget($this->widget);
	$this->endsect;
}

=item value

The value is true if the checkbox is checked, false otherwise.

=cut

sub value {
	my $this = shift;
	
	if ($this -> widget -> isChecked) {
		return "true";
	}
	else {
		return "false";
	}
}

=back

=head1 AUTHOR

Peter Rockai <mornfall@logisys.dyndns.org>
Sune Vuorela <sune@debian.org>

=cut

1
