#!/usr/bin/perl -w

=head1 NAME

Debian::DebConf::Element::Gtk::Select - Gtk select box

=cut

=head1 DESCRIPTION

This is an element on the debconf dialog box that lets the user
pick from a list of valid choices.

=cut


package Debian::DebConf::Element::Gtk::Select;
use Gtk;
use strict;
use Debian::DebConf::Element; # perlbug
use base qw(Debian::DebConf::Element::Select);

sub show {
	my $this = shift;
	
	my $vbox = new Gtk::VBox(0,5);
	my $text = $this->frontend->maketext(
			$this->question->extended_description);

	$vbox->pack_start($text, 1,1,0);
	$text->show();

	$this->{unchanged} = 1;
	$this->{newvalue} = undef;

	if (0) {
		$this->radio($vbox);
	} else {
		$this->dropdown($vbox);
	}

	my $result = $this->frontend->newques(
			$this->question->description, $vbox);

	return $this->{newvalue};
}

sub radio {
	my ($this, $vbox) = @_;
	my $radio;

	foreach my $opt ($this->question->choices_split) {
		if ($radio) {
			$radio = new Gtk::RadioButton($opt, $radio);
		} else {
			$radio = new Gtk::RadioButton($opt);
		}
		$radio->signal_connect("toggle",
			sub { 
				$this->{unchanged} = 0;
				$this->{newvalue} = $opt;
			});
		$radio->set_active(1) 
			if ((defined $this->question->value) && ($opt eq $this->question->value));
		$vbox->pack_start($radio, 0,0,0);
		$radio->show();
	}
	return;
}

sub dropdown {
	my ($this, $vbox) = @_;
	my $optmenu = new Gtk::OptionMenu;
	my $menu = new Gtk::Menu;
	my $menuitem;
	my $n = 0;
	my $hist;

	foreach my $opt ($this->question->choices_split) {
		$menuitem = new Gtk::RadioMenuItem($opt, $menuitem);
		$menu->append($menuitem);
		$menuitem->signal_connect("toggle",
			sub { 
				$this->{unchanged} = 0;
				$this->{newvalue} = $opt;
			});
		$menuitem->set_active(1), $hist = $n
			if ((defined $this->question->value) && ($opt eq $this->question->value));
		$menuitem->show();
		$n++;
	}

	$optmenu->set_menu($menu);
	$optmenu->set_history($hist);
	$optmenu->show;
	$vbox->pack_start($optmenu, 0,0,0);
}

1
