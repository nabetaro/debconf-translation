#!/usr/bin/perl -w

=head1 NAME

Debconf::Element::Gnome - gnome UI element

=cut

package Debconf::Element::Gnome;
use strict;
use utf8;
use Gtk2;
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

	$this->hbox(Gtk2::VBox->new(0, 10));

	$this->hline1(Gtk2::HBox->new(0, 10));
	$this->hline1->show;
	$this->line1(Gtk2::VBox->new(0, 10));
	$this->line1->show;
	$this->line1->pack_end ($this->hline1, 1, 1, 0);

	$this->hline2(Gtk2::HBox->new(0, 10));
	$this->hline2->show;
	$this->line2(Gtk2::VBox->new(0, 10));
	$this->line2->show;
	$this->line2->pack_end ($this->hline2, 1, 1, 0);

	$this->vbox(Gtk2::VBox->new(0, 5));
	$this->vbox->pack_start($this->line1, 0, 0, 0);
	$this->vbox->pack_start($this->line2, 1, 1, 0);
	$this->vbox->show;

	$this->hbox->pack_start($this->vbox, 1, 1, 0);
	$this->hbox->show;
	
	# default is not to be expanded or to filled
	$this->fill(0);
	$this->expand(0);
	$this->multiline(0);
}

=item addwidget

Packs the passed widget into the hbox.

=cut

sub addwidget {
	my $this=shift;
	my $widget=shift;

	if ($this->multiline == 0) {
	    $this->hline1->pack_start($widget, 1, 1, 0);
	}
	else {
	    $this->hline2->pack_start($widget, 1, 1, 0);
	}
}

=item adddescription

Packs a label containing the short description into the hbox.

=cut

sub adddescription {
	my $this=shift;

	my $label=Gtk2::Label->new($this->question->description);
	$label->show;
	$this->line1->pack_start($label, 0, 0, 0);
}

=item addbutton

Packs a button into the first line of the hbox. The button is added
at the end of the box.

=cut

sub addbutton {
	my $this=shift;
	my $text = shift;
	my $callback = shift;

	my $button = Gtk2::Button->new_with_label($text);
	$button->show;
	$button->signal_connect("clicked", $callback);

	my $vbox = Gtk2::VBox->new(0, 0);
	$vbox->show;
	$vbox->pack_start($button, 1, 0, 0);
	$this->hline1->pack_end($vbox, 0, 0, 0);
}

=item addhelp

Packs a help button into the hbox. The button is omitted if there is no
extended description to display as help.

=cut

sub addhelp {
	my $this=shift;
	
	my $help=$this->question->extended_description;
	return unless length $help;

	$this->addbutton(gettext("Help"), sub {
		my $dialog = Gtk2::MessageDialog->new(undef, "modal", "info",
						      "close", $help);
		$dialog->run;
		$dialog->destroy;
	});
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

Eric Gillespie <epg@debian.org>
Gustavo Noronha Silva <kov@debian.org>

=cut

1
