#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Gnome::Boolean - check box widget

=cut

package Debconf::Element::Gnome::Boolean;
use strict;
use Gtk2;
use Encode;
use utf8;
use base qw(Debconf::Element::Gnome);

=head1 DESCRIPTION

This is a check box widget.

=cut

sub init {
	my $this=shift;
	my $description=$this->question->description;
	
	$this->SUPER::init(@_);
	
	if ($this->is_unicode_locale()) {
		$description=decode("UTF-8", $description);
	}
	
	$this->widget(Gtk2::CheckButton->new($description));
	$this->widget->show;
	$this->widget->set_active(($this->question->value eq 'true') ? 1 : 0);
	$this->addwidget($this->widget);
	$this->addhelp;
}

=item value

The value is true if the checkbox is checked, false otherwise.

=cut

sub value {
	my $this=shift;

	if ($this->widget->get_active) {
		return "true";
	}
	else {
		return "false";
	}
}

=back

=head1 AUTHOR

Eric Gillespie <epg@debian.org>
Gustavo Noronha Silva <kov@debian.org>

=cut

1
