#!/usr/bin/perl -w

=head1 NAME

Debconf::FrontEnd::Gnome - GUI Gnome frontend

=cut

package Debconf::FrontEnd::Gnome;
use strict;
use Debconf::Gettext;
use Debconf::Config;
use base qw{Debconf::FrontEnd};

# Catch this so as not to confuse the poor users if Gtk or Gnome are not
# installed.
eval q{
    use Gtk;
    use Gnome;
};
die "Unable to load Gnome -- is libgnome-perl installed?\n"
	if $@;

=head1 DESCRIPTION

This FrontEnd is a Gnome UI for Debconf.

=head1 METHODS

=over 4

=item init

Set up most of the GUI.

=cut

our @ARGV_for_gnome=('--sm-disable');

sub init {
	my $this=shift;
	
	# Ya know, this really sucks. The authors of GTK seemed to just not
	# conceive of a program that can, *gasp*, work even if GTK doesn't
	# load. So this thing throws a fatal, essentially untrappable
	# error. Yeesh. Look how far I must go out of my way to make sure
	# it's not going to destroy debconf..
	if (fork) {
		wait(); # for child
		if ($? != 0) {
			die "DISPLAY problem?\n";
		}
	}
	else {
		@ARGV=@ARGV_for_gnome; # temporary change at first
		Gnome->init('Debconf');
		exit(0); # success
	}
	
	my @gnome_sucks=@ARGV;
	@ARGV=@ARGV_for_gnome;
	Gnome->init('Debconf');
	@ARGV=@gnome_sucks;
	
	$this->SUPER::init(@_);
	$this->interactive(1);
	$this->capb('backup');
	
	$this->win(Gtk::Window->new("toplevel"));
	$this->win->set_position(1);
	$this->win->set_default_size(600, 400);
	$this->win->set_title(gettext("Debconf"));
	$this->win->signal_connect("delete_event", sub { exit });
	
	$this->logo(Gtk::Gdk::ImlibImage->load_image(
	    "/usr/share/pixmaps/debian-logo.xpm"));
	
	$this->druid(Gnome::Druid->new);
	$this->druid->show;
	$this->win->add($this->druid);
	
	$this->druid_page(Gnome::DruidPageStandard->new);
	$this->druid_page->set_logo($this->logo);
	my $color = Gtk::Gdk::Color->parse_color('#006699');
	$this->druid_page->set_bg_color($color);
	$this->druid_page->set_logo_bg_color($color);
	$this->druid_page->signal_connect("back", sub {
		$this->goback(1);
		Gtk->main_quit;
		return 1;
	});
	$this->druid_page->signal_connect("next", sub {
		$this->goback(0);
		Gtk->main_quit;
		return 1;
	});
	$this->druid_page->signal_connect("cancel", sub { exit });
	$this->druid_page->show;
	$this->druid->append_page($this->druid_page);
	$this->mainbox(Gtk::ScrolledWindow->new);
	$this->mainbox->set_policy(1, 1);
	$this->mainbox->show;
	$this->vbox(Gtk::VBox->new(0, 10));
	$this->vbox->set_border_width(10);
	$this->vbox->show;
	$this->mainbox->add_with_viewport($this->vbox);
	$this->druid_page->vbox->pack_start($this->mainbox, 1, 1, 0);
}

=item go

Creates and lays out all the necessary widgets, then runs them to get
input.

=cut

sub go {
        my $this=shift;
	my @elements=@{$this->elements};
	
	my $interactive='';
	foreach my $element (@elements) {
		# Noninteractive elemements have no hboxes.
		next unless $element->hbox;

		$interactive=1;
		$this->vbox->pack_start($element->hbox, 
					$element->expand, $element->fill, 5);
	}

	if ($interactive) {
	        $this->druid_page->set_title($this->title);
		if ($this->capb_backup) {
			$this->druid->set_buttons_sensitive(1, 1, 1);
		}
		else {
			$this->druid->set_buttons_sensitive(0, 1, 1);
		}
		$this->win->show;
		Gtk->main;
		foreach my $element (@elements) {
			next unless $element->widget;
			$this->vbox->remove($element->hbox);
		}
	}

	# Display all elements. This does nothing for gnome
	# elements, but it causes noninteractive elements to do
	# their thing.
	foreach my $element (@elements) {
		$element->show;
	}

	return '' if $this->goback;
	return 1;
}

=back

=head1 AUTHOR

Eric Gillespie <epg@debian.org>

=cut

1
