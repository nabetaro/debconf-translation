#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Kde::String

=cut

package Debconf::Element::Kde::String;
use strict;
use QtCore4;
use QtGui4;
use base qw(Debconf::Element::Kde);
use Debconf::Encoding qw(to_Unicode);

=head1 DESCRIPTION

This is a string entry widget.

=head1 METHODS

=over 4

=item create

Creates and sets up the widget.

=cut

sub create {
	my $this=shift;
	
	$this->SUPER::create(@_);
	$this->startsect;
	$this->widget(Qt::LineEdit($this->cur->top));
	my $default='';
	$default=$this->question->value if defined $this->question->value;
	$this->widget->setText(to_Unicode($default));
	$this->adddescription;
	$this->addhelp;
	$this->addwidget ($this->widget);
	$this->endsect;
}

=item value

Gets the text in the widget.

=cut

sub value {
	my $this=shift;
	#FIXME encoding?
	return $this->widget->text();
}

=back

=head1 AUTHOR

Peter Rockai <mornfall@logisys.dyndns.org>

=cut

1
