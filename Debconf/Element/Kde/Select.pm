#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Kde::Select - select list widget

=cut

package Debconf::Element::Kde::Select;
use strict;
use QtCore4;
use QtGui4;
use base qw(Debconf::Element::Kde Debconf::Element::Select);
use Debconf::Encoding qw(to_Unicode);

=head1 DESCRIPTION

A drop down select list widget.

=head1 METHODS

=over 4

=item create

Creates and sets up the widget.

=cut

sub create {
	my $this=shift;
	
	my $default=$this->translate_default;
	my @choices=map { to_Unicode($_) } $this->question->choices_split;
	
	$this->SUPER::create(@_);
	$this->startsect;
	$this->widget(Qt::ComboBox($this->cur->top));
	$this->widget->show;
	$this->widget->addItems(\@choices);
	if (defined($default) and length($default) != 0) {
		for (my $i = 0 ; $i < @choices ; $i++) {
			if ($choices[$i] eq $default ) {
				$this->widget->setCurrentIndex($i);# //FIXME find right index to_Unicode($default));
				last;
			}
		}
	}
	$this->addwidget($this->description);
	$this->addhelp;
	$this->addwidget($this->widget);
	$this->endsect;
}

=item value

The value is the currently selected list item.

=cut

sub value {
	my $this=shift;
	
	my @choices=$this->question->choices_split;
	return $this->translate_to_C_uni($this->widget->currentText());
}

# Multiple inheritance means we get Debconf::Element::visible by default.
*visible = \&Debconf::Element::Select::visible;

=back

=head1 AUTHOR

Peter Rockai <mornfall@logisys.dyndns.org>

=cut

1
