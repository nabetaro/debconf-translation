#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Kde::Password - password entry widget

=cut

package Debconf::Element::Kde::Password;
use strict;
use Qt;
use base qw(Debconf::Element::Kde);

=head1 DESCRIPTION

This is a password entry widget.

=head1 METHODS

=over 4

=item create

Creates and sets up the widget, set it not to display its contents.

=cut

sub create {
	my $this=shift;
	
	$this->SUPER::create(@_);
	$this->startsect;
	$this->widget(Qt::LineEdit($this->cur->top));
	$this->widget->show;
	$this->widget->setEchoMode(2);
	$this->addhelp;
	my $b = $this->addhbox;
	$b->addWidget($this->description);
	$b->addWidget($this->widget);
	$this->endsect;
}

=item value

Of course the value is the content of the text entry field.
If the widget's value field is empty, display the default.

=cut

sub value {
	my $this=shift;
	
	my $text = $this->widget->text();
	$text = $this->question->value if $text eq '';
	return $text;
}

=back

=head1 AUTHOR
 
Peter Rockai <mornfall@logisys.dyndns.org>
  
=cut

1
