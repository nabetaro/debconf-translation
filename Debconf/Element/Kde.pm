#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Kde::ElementWidget - Kde UI Widget

=cut

package Debconf::Element::Kde::ElementWidget;
use Qt;
use Qt::isa @ISA = qw(Qt::Widget);
use Qt::attributes qw(layout mytop toplayout);

=head1 DESCRIPTION

This is a helper module for Debconf::Element::Kde, it represents one KDE
widget that is part of a debconf display Element.

=head1 METHODS

=over 4

=item NEW

Sets up the element.

=cut

sub NEW {
	shift->SUPER::NEW (@_[0..2]);
	mytop = undef;
}

=item settop

Sets the top of the widget.

=cut

sub settop {
    mytop = shift;
}

=item init

Initializes the widget.

=cut

sub init {
	setSizePolicy(Qt::SizePolicy(1, &Qt::SizePolicy::Preferred, 0, 
	                             0, sizePolicy()->hasHeightForWidth()));
	toplayout = layout = Qt::VBoxLayout(this, 0, 10, "TopVBox");
	if (mytop) {
		toplayout->addWidget (mytop);
		layout = Qt::VBoxLayout(mytop, 15, 5, "TopVBox");
	}
	else {
		mytop = this;
	}
}

=item destroy

Destroy the widget.

=cut

sub destroy {
	toplayout -> remove (mytop);
	undef mytop;
}

=item top

Returns the top of the widget.

=cut

sub top {
    return mytop;
}

=item addwidget

Adds the passed widget to the latout.

=cut

sub addwidget {
    layout->addWidget(@_);
}

=item addlayout

Adds the passed layout.

=cut

sub addlayout {
    layout->addLayout (@_);
}

=item additem

Adds the passed item to the layout.

=cut

sub additem {
    my $item=shift;
    layout->addItem($item);
}

=back

=head1 AUTHOR

Peter Rockai <mornfall@logisys.dyndns.org>

=cut

# XXX The above docs suck, and shouldn't it be in its own file?


=head1 NAME

Debconf::Element::Kde - kde UI element

=cut

package Debconf::Element::Kde;
use strict;
use Qt;
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
	$this->top->destroy;
	$this->top->reparent(undef, 0, Qt::Point(0, 0), 0);
	$this->top->DESTROY;
	$this->top(undef);
}

=item addhbox

Adds a kbox to the layout, and returns it.

=cut

sub addhbox {
	my $this=shift;
	my $hbox = Qt::HBoxLayout(undef, 0, 8, "SubHBox");
	$this->cur->addlayout($hbox);
	return $hbox;
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
	$label->setText(to_Unicode($this->question->description));
	$label->setSizePolicy(Qt::SizePolicy(1, 1, 0, 0, $label->sizePolicy()->hasHeightForWidth()));
	$label->show;
	return $label;
}

=item startsect

Creates a groupbox to hold the set of widgets used for this element,
and points cur at it so new widgets go in there.

=cut

sub startsect {
	my $this = shift;
	my $ew = Debconf::Element::Kde::ElementWidget($this->top);
	my $mytop = Qt::GroupBox($ew);
	$ew->settop($mytop);
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
	$label->setTextFormat(&Qt::AutoText);
	$label->setAlignment(&Qt::WordBreak | &Qt::AlignJustify);
	$label->setSizePolicy(Qt::SizePolicy(&Qt::SizePolicy::Minimum,
	                                     &Qt::SizePolicy::Fixed,
	                                     0, 0, $label->sizePolicy()->hasHeightForWidth()));
	$this->addwidget($label); # line1
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

=cut

1
