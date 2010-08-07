#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Kde::ElementWidget - Kde UI Widget

=cut

package Debconf::Element::Kde::ElementWidget;
use QtCore4;
use QtCore4::isa @ISA = qw(Qt::Widget);
use QtGui4;
#use Qt::attributes qw(layout mytop toplayout);

=head1 DESCRIPTION

This is a helper module for Debconf::Element::Kde, it represents one KDE
widget that is part of a debconf display Element.

=head1 METHODS

=over 4

=item NEW

Sets up the element.

=cut

sub NEW {
	shift->SUPER::NEW ($_[0]);
	this->{mytop} = undef;
}

=item settop

Sets the top of the widget.

=cut

sub settop {
    this->{mytop} = shift;
}

=item init

Initializes the widget.

=cut

sub init {
	this->{toplayout} =  Qt::VBoxLayout(this);
	this->{mytop} = Qt::Widget(this);
	this->{toplayout}->addWidget (this->{mytop});
	this->{layout} = Qt::VBoxLayout();
	this->{mytop}->setLayout(this->{layout});
}

=item destroy

Destroy the widget.

=cut

sub destroy {
	this->{toplayout} -> removeWidget (this->{mytop});
	undef this->{mytop};
}

=item top

Returns the top of the widget.

=cut

sub top {
    return this->{mytop};
}

=item addwidget

Adds the passed widget to the latout.

=cut

sub addwidget {
    this->{layout}->addWidget(@_);
}

=item addlayout

Adds the passed layout.

=cut

sub addlayout {
    this->{layout}->addLayout (@_);
}


=head1 AUTHOR

Peter Rockai <mornfall@logisys.dyndns.org>
Sune Vuorela <sune@vuorela.dk>

=cut

# XXX The above docs suck, and shouldn't it be in its own file?


=head1 NAME

Debconf::Element::Kde - kde UI element

=cut

package Debconf::Element::Kde;
use strict;
use QtCore4;
use QtGui4;
use Debconf::Gettext;
use base qw(Debconf::Element);
use Debconf::Element::Kde::ElementWidget;
use Debconf::Encoding qw(to_Unicode);

=head1 DESCRIPTION

This is a type of Element used by the kde FrontEnd.

=head1 METHODS

=over 4

=item create

Called to create a the necessary Qt widgets for the element..

=cut

sub create {
	my $this=shift;
	$this->parent(shift);
	$this->top(Debconf::Element::Kde::ElementWidget($this->parent, undef,
	                                                undef, undef));
	$this->top->init;
	$this->top->show;
}

=item destroy

Called to destroy the element.

=cut

sub destroy {
	my $this=shift;
	$this->top(undef);
}

=item addwidget

Adds a widget.

=cut

sub addwidget {
	my $this=shift;
	my $widget=shift;
	$this->cur->addwidget($widget);
}

=item description

Sets up a label to display the description of the element's question.

=cut

sub description {
	my $this=shift;
	my $label=Qt::Label($this->cur->top);
	$label->setText("<b>".to_Unicode($this->question->description."</b>"));
	$label->show;
	return $label;
}

=item startsect

=cut

sub startsect {
	my $this = shift;
	my $ew = Debconf::Element::Kde::ElementWidget($this->top);
	$ew->init;
	$this->cur($ew);
	$this->top->addwidget($ew);
	$ew->show;
}

=item endsect

End adding widgets for this element.

=cut

sub endsect {
	my $this = shift;
	$this->cur($this->top);
}

=item adddescription

Creates a label for the description of this Element.

=cut

sub adddescription {
	my $this=shift;
	my $label=$this->description;
	$this->addwidget($label);
}

=item addhelp

Creates a label to display the entended descrition of the Question
associated with this Element,

=cut

sub addhelp {
	my $this=shift;
    
	my $help=to_Unicode($this->question->extended_description);
	return unless length $help;
	my $label=Qt::Label($this->cur->top);
	$label->setText($help);
	$label->setWordWrap(1);
	$this->addwidget($label); # line1
	$label->setMargin(5);
	$label->show;
}

=item value

Return the value the user entered.

Defaults to returning nothing.

=cut

sub value {
	my $this=shift;
	return '';
}

=back

=head1 AUTHOR

Peter Rockai <mornfall@logisys.dyndns.org>
Sune Vuorela <sune@vuorela.org>

=cut

1
