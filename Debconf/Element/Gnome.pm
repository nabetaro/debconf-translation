#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Gnome - gnome UI element

=cut

package Debconf::Element::Gnome;
use strict;
use Gtk;
use Debconf::Gettext;
use base qw(Debconf::Element);

=head1 DESCRIPTION

This is a type of Element used by the gnome FrontEnd. It contains a hbox,
into which the gnome UI element and any associated lables, help buttons,
etc, are packaged.

=head1 FIELDS

=over 4

=item hbox

This is the hbox that holds all the widgets for this element.

=back

=head1 METHODS

=over 4

=item init

Sets up the hbox.

=cut

sub init {
	my $this=shift;

	$this->hbox(Gtk::HBox->new(0, 10));
	$this->hbox->show;
}

=item addwidget

Packs the passed widget into the hbox.

=cut

sub addwidget {
	my $this=shift;
	my $widget=shift;

	$this->hbox->pack_start($widget, 1, 1, 0);
}

=item adddescription

Packs a label containing the short description into the hbox.

=cut

sub adddescription {
	my $this=shift;

	my $label=Gtk::Label->new($this->question->description);
	$label->show;
	$this->hbox->pack_start($label, 0, 0, 0);
}

=item addbutton

Packs a help button into the hbox. The button is omitted if there is no
extended description to display as help.

=cut

sub addbutton {
	my $this=shift;
	
	my $help=$this->question->extended_description;
	return unless length $help;
	my $button=Gtk::Button->new_with_label(gettext("Help"));
	$button->show;
	$button->signal_connect("clicked", sub {
		my $dialog = Gnome::Dialog->new(gettext("Help"), "Button_Ok");
		my $label = Gtk::Label->new($help);
		$label->set_line_wrap(1);
		$label->show;
		$dialog->vbox->add($label);
		$dialog->run;
		$dialog->close;
	});
	my $vbox = Gtk::VBox->new(0, 0);
	$vbox->show;
	$vbox->pack_start($button, 1, 0, 0);
	$this->hbox->pack_start($vbox, 0, 0, 0);
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

Joey Hess <joey@kitenet.net>

=cut

1
